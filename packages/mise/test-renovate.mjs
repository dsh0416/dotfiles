// Exercise Renovate's real extraction, datasource templates, and file updater.
import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const [renovatePath, configPath, manifestPath] = process.argv.slice(2);
const load = (path) => import(pathToFileURL(join(renovatePath, "dist", path)));
const { extractPackageFile } = await load("modules/manager/custom/regex/index.js");
const { massageCustomDatasourceConfig } = await load("modules/datasource/custom/utils.js");
const { doAutoReplace } = await load("workers/repository/update/branch/auto-replace.js");
const { api: semver } = await load("modules/versioning/semver/index.js");
const { GlobalConfig } = await load("config/global.js");
const { init: initLogger } = await load("logger/index.js");
await initLogger();
const require = createRequire(join(renovatePath, "package.json"));
const jsonata = require("jsonata");

const config = JSON.parse(await readFile(configPath, "utf8"));
const manager = config.customManagers.find((item) =>
  item.datasourceTemplate === "custom.mise-releases"
);
const packageFile = "packages/mise/sources.json";
let content = await readFile(manifestPath, "utf8");
const extracted = extractPackageFile(content, packageFile, manager);
const platforms = ["macos-arm64", "linux-arm64-musl", "linux-x64-musl"];
assert.deepEqual(
  extracted.deps.map((dep) => dep.packageName).sort(),
  [...platforms].sort(),
);
assert.ok(semver.isGreaterThan("2026.10.1", "2026.9.30"));
assert.ok(semver.isGreaterThan("2027.1.1", "2026.12.31"));

// The latest endpoint returns one release object, not an array of releases.
const version = "2027.1.2";
const release = {
  tag_name: `v${version}`,
  draft: false,
  prerelease: false,
  published_at: "2027-01-02T00:00:00Z",
  html_url: `https://github.com/jdx/mise/releases/tag/v${version}`,
  assets: platforms.map((platform, index) => ({
    name: `mise-v${version}-${platform}.tar.gz`,
    digest: `sha256:${String(index + 1).repeat(64)}`,
  })),
};
const invalidReleases = [
  ["draft", { ...release, draft: true }],
  ["prerelease", { ...release, prerelease: true }],
  ...["2027.1.2", "v27.1.2", "v2027.1", "v2027.1.2-beta.1", "latest"].map(
    (tag_name) => [`invalid tag ${tag_name}`, {
      ...release,
      tag_name,
      assets: release.assets.map((asset, index) => ({
        ...asset,
        name: `mise-${tag_name}-${platforms[index]}.tar.gz`,
      })),
    }],
  ),
  ...platforms.flatMap((platform, index) => [
    [`missing ${platform}`, {
      ...release,
      assets: release.assets.filter((_, assetIndex) => assetIndex !== index),
    }],
    [`wrong version in ${platform} filename`, {
      ...release,
      assets: release.assets.map((asset, assetIndex) => assetIndex === index
        ? { ...asset, name: asset.name.replace(version, "2026.12.31") }
        : asset),
    }],
    ...[undefined, null, 123, "sha256:invalid", `sha512:${"a".repeat(64)}`].map(
      (digest) => [`invalid digest ${digest} for ${platform}`, {
        ...release,
        assets: release.assets.map((asset, assetIndex) => assetIndex === index
          ? { ...asset, digest }
          : asset),
      }],
    ),
  ]),
  ["duplicate asset replacing a platform", {
    ...release,
    assets: [release.assets[0], release.assets[0], release.assets[1]],
  }],
];

const temporary = await mkdtemp(join(tmpdir(), "renovate-mise-"));
GlobalConfig.set({ localDir: temporary, platform: "local" });
try {
  for (const [index, dep] of extracted.deps.entries()) {
    const datasource = massageCustomDatasourceConfig("mise-releases", {
      customDatasources: config.customDatasources,
      packageName: dep.packageName,
      currentValue: dep.currentValue,
    });
    assert.equal(
      datasource.defaultRegistryUrlTemplate,
      "https://api.github.com/repos/jdx/mise/releases/latest",
    );
    const expression = jsonata(datasource.transformTemplates[0]);
    for (const [label, invalidRelease] of invalidReleases) {
      const result = await expression.evaluate(invalidRelease);
      assert.deepEqual(result.releases, [], `${dep.packageName}: ${label}`);
    }
    const result = await expression.evaluate(release);
    const digest = release.assets.find((asset) =>
      asset.name === `mise-v${version}-${dep.packageName}.tar.gz`
    ).digest.slice(7);
    assert.deepEqual(JSON.parse(JSON.stringify(result.releases)), [{
      version,
      digest,
      releaseTimestamp: release.published_at,
      changelogUrl: release.html_url,
    }]);
    assert.equal(result.sourceUrl, "https://github.com/jdx/mise");
    const withOtherAssets = await expression.evaluate({
      ...release,
      assets: [...release.assets, { name: "SHASUMS256.txt" }],
    });
    assert.deepEqual(withOtherAssets, result);
    content = await doAutoReplace({
      ...manager,
      ...dep,
      manager: "regex",
      packageFile,
      depIndex: index,
      newValue: version,
      newDigest: digest,
      autoReplaceGlobalMatch: true,
    }, content, false);
    assert.ok(content, `Renovate must update ${dep.packageName}`);
  }
  const updated = JSON.parse(content);
  for (const asset of Object.values(updated.assets)) {
    assert.equal(asset.version, version);
    assert.equal(asset.sha256, release.assets.find((entry) =>
      entry.name === `mise-v${version}-${asset.platform}.tar.gz`
    ).digest.slice(7));
  }
  // GitHub can replace an archive without changing the release version.
  const refreshedDigest = "f".repeat(64);
  const refreshed = extractPackageFile(content, packageFile, manager);
  for (const [index, dep] of refreshed.deps.entries()) {
    content = await doAutoReplace({
      ...manager,
      ...dep,
      manager: "regex",
      packageFile,
      depIndex: index,
      newValue: dep.currentValue,
      newDigest: refreshedDigest,
      autoReplaceGlobalMatch: true,
    }, content, false);
    assert.ok(content, `Renovate must refresh the digest for ${dep.packageName}`);
  }
  for (const asset of Object.values(JSON.parse(content).assets)) {
    assert.equal(asset.version, version);
    assert.equal(asset.sha256, refreshedDigest);
  }
  console.log("mise Renovate extraction, release filtering, and three-platform update passed");
} finally {
  GlobalConfig.reset();
  await rm(temporary, { recursive: true, force: true });
}

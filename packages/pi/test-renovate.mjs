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
const { GlobalConfig } = await load("config/global.js");
const { init: initLogger } = await load("logger/index.js");
await initLogger();
const require = createRequire(join(renovatePath, "package.json"));
const jsonata = require("jsonata");

const config = JSON.parse(await readFile(configPath, "utf8"));
const manager = config.customManagers.find((item) =>
  item.datasourceTemplate === "custom.pi-releases"
);
const packageFile = "packages/pi/sources.json";
let content = await readFile(manifestPath, "utf8");
const extracted = extractPackageFile(content, packageFile, manager);
const platforms = ["darwin-arm64", "linux-arm64", "linux-x64"];
assert.deepEqual(extracted.deps.map((dep) => dep.packageName).sort(), platforms);

const version = "9.9.9";
const release = {
  tag_name: `v${version}`,
  draft: false,
  prerelease: false,
  published_at: "2026-09-30T00:00:00Z",
  html_url: `https://github.com/earendil-works/pi/releases/tag/v${version}`,
  assets: platforms.map((platform, index) => ({
    name: `pi-${platform}.tar.gz`,
    digest: `sha256:${String(index + 1).repeat(64)}`,
  })),
};
const incomplete = { ...release, assets: release.assets.slice(1) };
const withoutDigests = {
  ...release,
  assets: release.assets.map((asset) => ({ name: asset.name })),
};
const nullDigests = {
  ...release,
  assets: release.assets.map((asset) => ({ ...asset, digest: null })),
};
const invalidDigests = {
  ...release,
  assets: release.assets.map((asset) => ({ ...asset, digest: "sha256:invalid" })),
};

const temporary = await mkdtemp(join(tmpdir(), "renovate-pi-"));
GlobalConfig.set({ localDir: temporary, platform: "local" });
try {
  for (const [index, dep] of extracted.deps.entries()) {
    const datasource = massageCustomDatasourceConfig("pi-releases", {
      customDatasources: config.customDatasources,
      packageName: dep.packageName,
      currentValue: dep.currentValue,
    });
    const expression = jsonata(datasource.transformTemplates[0]);
    const result = await expression.evaluate([
      release,
      { ...release, draft: true },
      { ...release, prerelease: true },
      incomplete,
      withoutDigests,
      nullDigests,
      invalidDigests,
    ]);
    const digest = release.assets.find((asset) =>
      asset.name === `pi-${dep.packageName}.tar.gz`
    ).digest.slice(7);
    assert.deepEqual(JSON.parse(JSON.stringify(result.releases)), [{
      version,
      digest,
      releaseTimestamp: release.published_at,
      changelogUrl: release.html_url,
    }]);
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
      entry.name === `pi-${asset.platform}.tar.gz`
    ).digest.slice(7));
  }
  console.log("Pi Renovate extraction, release filtering, and three-platform update passed");
} finally {
  GlobalConfig.reset();
  await rm(temporary, { recursive: true, force: true });
}

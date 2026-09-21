#!/usr/bin/env python3
"""Pin an upstream mise release after verifying every supported archive."""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import urllib.request


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "dotfiles-mise-updater"})
    return urllib.request.urlopen(request, timeout=60)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", nargs="?", help="release version; defaults to latest stable")
    parser.add_argument("--manifest", type=Path, default=Path(__file__).with_name("sources.json"))
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())

    version = args.version.removeprefix("v") if args.version else None
    if version is not None and not re.fullmatch(r"\d{4}\.\d+\.\d+", version):
        parser.error("version must have the form 2026.9.12")
    endpoint = f"tags/v{version}" if version else "latest"
    with fetch(f"https://api.github.com/repos/jdx/mise/releases/{endpoint}") as response:
        release = json.load(response)
    if release["draft"] or release["prerelease"]:
        raise ValueError("Only published stable releases are supported")
    version = release["tag_name"].removeprefix("v")
    if not re.fullmatch(r"\d{4}\.\d+\.\d+", version):
        raise ValueError(f"Unexpected release tag: {release['tag_name']}")

    base_url = f"https://github.com/jdx/mise/releases/download/v{version}"
    with fetch(f"{base_url}/SHASUMS256.txt") as response:
        checksums = dict(
            (name.lstrip("*").removeprefix("./"), digest)
            for digest, name in (line.split() for line in response.read().decode().splitlines() if line)
        )
    release_assets = {asset["name"]: asset for asset in release["assets"]}
    for system, asset in manifest["assets"].items():
        name = f"mise-v{version}-{asset['platform']}.tar.gz"
        expected = checksums[name]
        api_digest = release_assets[name].get("digest")
        if api_digest and api_digest != f"sha256:{expected}":
            raise ValueError(f"Release metadata and checksum file disagree for {name}")
        digest = hashlib.sha256()
        with fetch(f"{base_url}/{name}") as response:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
        if digest.hexdigest() != expected:
            raise ValueError(f"Checksum mismatch for {name}")
        asset["hash"] = "sha256-" + base64.b64encode(digest.digest()).decode()
        print(f"Verified {system}: {name}", flush=True)

    # Replace the manifest only after all platforms have been verified.
    manifest["version"] = version
    rendered = json.dumps(manifest, indent=2) + "\n"
    if args.manifest.read_text() != rendered:
        temporary = args.manifest.with_suffix(".json.tmp")
        temporary.write_text(rendered)
        temporary.replace(args.manifest)
    print(f"Pinned mise {version} in {args.manifest}")


if __name__ == "__main__":
    main()

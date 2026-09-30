#!/usr/bin/env python3
"""Pin an upstream Pi release after verifying every supported archive."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import urllib.request


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "dotfiles-pi-updater"})
    return urllib.request.urlopen(request, timeout=60)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", nargs="?", help="release version; defaults to latest stable")
    parser.add_argument("--manifest", type=Path, default=Path(__file__).with_name("sources.json"))
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())

    version = args.version.removeprefix("v") if args.version else None
    if version is not None and not re.fullmatch(r"\d+\.\d+\.\d+", version):
        parser.error("version must have the form 0.99.1")
    endpoint = f"tags/v{version}" if version else "latest"
    with fetch(f"https://api.github.com/repos/earendil-works/pi/releases/{endpoint}") as response:
        release = json.load(response)
    if release["draft"] or release["prerelease"]:
        raise ValueError("Only published stable releases are supported")
    version = release["tag_name"].removeprefix("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError(f"Unexpected release tag: {release['tag_name']}")

    base_url = f"https://github.com/earendil-works/pi/releases/download/v{version}"
    with fetch(f"{base_url}/SHA256SUMS") as response:
        checksums = dict(
            (name.lstrip("*").removeprefix("./"), digest)
            for digest, name in (line.split() for line in response.read().decode().splitlines() if line)
        )
    release_assets = {asset["name"]: asset for asset in release["assets"]}
    for system, asset in manifest["assets"].items():
        name = f"pi-{asset['platform']}.tar.gz"
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
        asset["version"] = version
        asset["sha256"] = digest.hexdigest()
        print(f"Verified {system}: {name}", flush=True)

    # Replace the manifest only after every supported archive passes verification.
    rendered = json.dumps(manifest, indent=2) + "\n"
    if args.manifest.read_text() != rendered:
        temporary = args.manifest.with_suffix(".json.tmp")
        temporary.write_text(rendered)
        temporary.replace(args.manifest)
    print(f"Pinned Pi {version} in {args.manifest}")


if __name__ == "__main__":
    main()

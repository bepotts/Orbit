#!/bin/bash
# Use the same formatter release on developer Macs, act, and GitHub runners.
set -euo pipefail

formatter_version=0.64.0
archive_sha256=95ea62625d0b898a7af870293311ae6f09e4a3147ecd900593687e4b9ab2fd98
project_root=$(cd "$(dirname "$0")/.." && pwd)
formatter_dir="$project_root/.build/tools/swiftformat-$formatter_version"
formatter_binary="$formatter_dir/swiftformat"

if [[ ! -x "$formatter_binary" ]]; then
    mkdir -p "$formatter_dir"
    download_dir=$(mktemp -d)
    trap 'rm -rf "$download_dir"' EXIT
    curl --fail --location --silent --show-error \
        "https://github.com/nicklockwood/SwiftFormat/releases/download/$formatter_version/swiftformat.zip" \
        --output "$download_dir/swiftformat.zip"
    echo "$archive_sha256  $download_dir/swiftformat.zip" | shasum -a 256 --check --status
    unzip -q "$download_dir/swiftformat.zip" -d "$download_dir/unpacked"
    install -m 755 "$download_dir/unpacked/swiftformat" "$formatter_binary"
fi

installed_version=$("$formatter_binary" --version)
if [[ "$installed_version" != "$formatter_version" ]]; then
    echo "Expected SwiftFormat $formatter_version, found $installed_version" >&2
    exit 1
fi

"$formatter_binary" "$@"

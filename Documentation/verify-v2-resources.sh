#!/usr/bin/env bash
set -euo pipefail

documentation_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resources_dir="$documentation_dir/../Sources/HL7Swift/Spec/Resources"
inventory_file="$documentation_dir/HL7V2_RESOURCES.lock"

sha256() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$@"
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$@"
    else
        echo "SHA-256 tool not found (shasum or sha256sum required)" >&2
        return 1
    fi
}

versions_checked=0
while read -r version expected_count expected_digest; do
    [[ -z "${version:-}" || "$version" == \#* ]] && continue
    directory="$resources_dir/v$version"
    if [[ ! -d "$directory" ]]; then
        echo "Missing resource directory: v$version" >&2
        exit 1
    fi

    # Finder metadata is local to macOS checkouts and is not part of the
    # tracked specification inventory.
    unexpected_file="$(find "$directory" -type f ! -name '*.xsd' ! -name '.DS_Store' -print -quit)"
    if [[ -n "$unexpected_file" ]]; then
        echo "Unexpected non-XSD resource: $unexpected_file" >&2
        exit 1
    fi

    actual_count="$(find "$directory" -type f -name '*.xsd' | wc -l | tr -d '[:space:]')"
    actual_digest="$(
        find "$directory" -type f -name '*.xsd' | LC_ALL=C sort |
        while IFS= read -r file; do
            relative_path="${file#"$directory"/}"
            printf '%s  %s\n' "$(sha256 "$file" | awk '{print $1}')" "$relative_path"
        done | sha256 | awk '{print $1}'
    )"

    if [[ "$actual_count" != "$expected_count" || "$actual_digest" != "$expected_digest" ]]; then
        echo "Resource drift in v$version: count=$actual_count sha256_tree=$actual_digest" >&2
        exit 1
    fi
    echo "v$version verified ($actual_count XSD files)"
    versions_checked=$((versions_checked + 1))
done < "$inventory_file"

directory_count="$(find "$resources_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d '[:space:]')"
if [[ "$directory_count" != "$versions_checked" ]]; then
    echo "Unexpected version directory: inventory=$versions_checked actual=$directory_count" >&2
    exit 1
fi

echo "Verified $versions_checked version directories."

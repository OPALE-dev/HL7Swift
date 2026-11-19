#!/usr/bin/env bash

# Builds the static DocC site of the library products, combined under one
# landing page.
# Usage: build.sh [output] [hosting-base-path]

set -euo pipefail

output="${1:-.build/documentation}"
base_path="${2:-}"

case "$output" in
  ""|"/"|"."|"..")
    echo "Refusing unsafe documentation output path: '$output'" >&2
    exit 2
    ;;
esac

if [[ -e "$output" ]]; then
  echo "Documentation output already exists: $output" >&2
  echo "Choose a new path or remove that generated directory first." >&2
  exit 2
fi

mkdir -p "$(dirname "$output")"

arguments=(
  swift package
  --allow-writing-to-directory "$output"
  generate-documentation
  --target HL7Core --target HL7V2 --target FHIR --target CDA --target HL7Mapping
  --enable-experimental-combined-documentation
  --output-path "$output"
  --transform-for-static-hosting
  --warnings-as-errors
)
if [[ -n "$base_path" ]]; then
  arguments+=(--hosting-base-path "$base_path")
fi
"${arguments[@]}"
touch "$output/.nojekyll"

#!/usr/bin/env bash
set -euo pipefail

# The former lockfile remains historical provenance. Current distribution
# must contain no licensed HL7 schema artefacts in library sources.
repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if find "$repository_dir/Sources" -type f -name '*.xsd' -print -quit | grep -q .; then
    echo "HL7 specification XSDs must not be distributed in Sources" >&2
    exit 1
fi
echo "No HL7 specification XSDs in Sources."

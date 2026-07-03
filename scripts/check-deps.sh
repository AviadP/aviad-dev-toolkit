#!/usr/bin/env bash
set -euo pipefail

# Dependency security snapshot via OSV.dev + registry metadata.
# Replaces per-package WebSearch rounds during security reviews.
#
# Usage: check-deps.sh <ecosystem> <package> [package...]
#   ecosystem: PyPI | npm | crates.io | RubyGems | Go | Maven | Packagist | NuGet
#
# Per package: known OSV vulnerability count + IDs, and (PyPI/npm) the
# latest version with its release date. Degrades gracefully offline.

ECOSYSTEM="${1:?Usage: check-deps.sh <ecosystem> <package> [package...]}"
shift
[[ $# -ge 1 ]] || { echo "ERROR: no packages given" >&2; exit 1; }

for PKG in "$@"; do
    echo "## ${PKG} (${ECOSYSTEM})"

    # --- Known vulnerabilities (any version) from OSV.dev ---
    OSV_BODY=$(jq -n --arg name "$PKG" --arg eco "$ECOSYSTEM" \
        '{package: {name: $name, ecosystem: $eco}}')
    OSV=$(curl -sf --max-time 10 "https://api.osv.dev/v1/query" -d "$OSV_BODY" || echo "")

    if [[ -z "$OSV" ]]; then
        echo "- OSV query failed (network?) — verify manually or run the local audit tool"
    else
        COUNT=$(echo "$OSV" | jq '[.vulns[]?] | length')
        if [[ "$COUNT" -eq 0 ]]; then
            echo "- Known vulnerabilities: none in OSV"
        else
            echo "- Known vulnerabilities: ${COUNT} historical (verify which affect the version you plan to use)"
            echo "$OSV" | jq -r '[.vulns[]? | .id] | .[0:8][] | "  - " + .'
        fi
    fi

    # --- Latest version + release date from the registry ---
    case "$ECOSYSTEM" in
        PyPI)
            META=$(curl -sf --max-time 10 "https://pypi.org/pypi/${PKG}/json" || echo "")
            if [[ -n "$META" ]]; then
                LATEST=$(echo "$META" | jq -r '.info.version')
                LAST_DATE=$(echo "$META" | jq -r --arg v "$LATEST" \
                    '.releases[$v][0].upload_time_iso_8601 // "unknown"' | cut -dT -f1)
                echo "- Latest: ${LATEST} (released ${LAST_DATE})"
            else
                echo "- PyPI lookup failed — package may not exist (typosquat check!)"
            fi
            ;;
        npm)
            PKG_URL="${PKG//\//%2F}"   # scoped packages: @scope/name → @scope%2Fname
            META=$(curl -sf --max-time 10 "https://registry.npmjs.org/${PKG_URL}" || echo "")
            if [[ -n "$META" ]]; then
                LATEST=$(echo "$META" | jq -r '.["dist-tags"].latest // "unknown"')
                LAST_DATE=$(echo "$META" | jq -r --arg v "$LATEST" '.time[$v] // "unknown"' | cut -dT -f1)
                echo "- Latest: ${LATEST} (released ${LAST_DATE})"
            else
                echo "- npm lookup failed — package may not exist (typosquat check!)"
            fi
            ;;
        *)
            echo "- Freshness check not implemented for ${ECOSYSTEM} — check the registry manually"
            ;;
    esac
    echo
done

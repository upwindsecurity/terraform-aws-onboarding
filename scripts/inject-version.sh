#!/usr/bin/env bash
set -euo pipefail

VERSION="$1"

for module in modules/*; do
  [ -d "$module" ] || continue

  FILE="$module/version.tf"

  cat > "$FILE" <<EOF
locals {
  upwind_version = "TF-${VERSION}"
}
EOF

  echo "Updated $FILE"
done
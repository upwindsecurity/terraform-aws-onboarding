#!/usr/bin/env bash
set -euo pipefail

VERSION="$1"

for module in modules/*; do
  [ -d "$module" ] || continue

  cat > "$module/version.tf" <<EOF
locals {
  upwind_version = "TF-${VERSION}"
}
EOF

done
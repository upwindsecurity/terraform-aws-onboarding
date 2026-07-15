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

# Stamp the version into every other .tf file that declares upwind_version
# (e.g. submodule locals.tf files that ship with a "VERSION_UNDEFINED" default).
#
# We match on the assignment rather than the placeholder token so this stays
# idempotent across releases: after the first release the value is already
# "TF-x.y.z", and matching "VERSION_UNDEFINED" would silently stop working.
while IFS= read -r file; do
  tmp="$(mktemp)"
  sed -E "s/(upwind_version[[:space:]]*=[[:space:]]*)\"[^\"]*\"/\1\"TF-${VERSION}\"/" "$file" > "$tmp"
  mv "$tmp" "$file"
done < <(grep -rl --include='*.tf' 'upwind_version[[:space:]]*=' modules)
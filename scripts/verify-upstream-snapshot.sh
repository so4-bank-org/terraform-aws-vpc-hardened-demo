#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

# This is the Git tree of terraform-aws-modules/terraform-aws-vpc v5.19.0,
# commit 961c9b51e3ed3959d9419f019e7085c087bf7297.
expected_tree="54066e3843bf9844727fdccf800e435018fa2b61"
actual_tree="$(git rev-parse --verify HEAD:modules/upstream)"

if [[ "$actual_tree" != "$expected_tree" ]]; then
  echo "Vendored upstream tree differs from the pinned v5.19.0 source." >&2
  echo "Expected: $expected_tree; actual: $actual_tree" >&2
  exit 1
fi

if ! git diff --quiet HEAD -- modules/upstream ||
   [[ -n "$(git ls-files --others --exclude-standard modules/upstream)" ]]; then
  echo "Vendored upstream source has uncommitted changes." >&2
  exit 1
fi

echo "Vendored upstream source matches Git tree $expected_tree."

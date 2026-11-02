#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/sazli-check.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT
mkdir -p "$check_dir/module-cache"

# Only needed when the host environment prevents Swift's nested macro sandbox.
if [ "${SAZLI_DISABLE_PLUGIN_SANDBOX:-0}" = 1 ]; then
    set -- -Xfrontend -disable-sandbox
else
    set --
fi
xcrun swiftc -swift-version 6 -parse-as-library "$@" \
    -module-cache-path "$check_dir/module-cache" \
    Sazli/Models/*.swift \
    Sazli/Services/RecipeText.swift \
    Sazli/Services/SourceLink.swift \
    Sazli/Services/RecipeDraft.swift \
    Sazli/Services/RecipeStore.swift \
    Scripts/PersistenceCheck.swift \
    -o "$check_dir/persistence-check"

for phase in create verify-create edit verify-edit delete verify-delete; do
    "$check_dir/persistence-check" "$phase" "$check_dir/recipes.store"
done

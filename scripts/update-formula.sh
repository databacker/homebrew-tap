#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.2.3"
    exit 1
fi

VERSION="$1"
FORMULA_FILE="Formula/mysql-backup.rb"
FORMULA_FILE_TMPL="Formula/mysql-backup.rb.in"
FORMULA_FILE_WORKING="${FORMULA_FILE}.work"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "$TEMP_DIR"' EXIT

if [ "$VERSION" = "latest" ]; then
    echo "Fetching latest release version from GitHub..."
    VERSION=$(curl -s https://api.github.com/repos/databacker/mysql-backup/releases/latest | jq -r '.tag_name')
    if [ -z "$VERSION" ]; then
        echo "Error: Could not determine latest release version."
        exit 1
    fi
    echo "Latest release version is $VERSION"
fi

echo "Updating mysql-backup formula to version $VERSION"

echo "Fetching release assets from GitHub API..."
ASSETS_JSON=$(curl -s "https://api.github.com/repos/databacker/mysql-backup/releases/tags/${VERSION}")
if [ -z "$ASSETS_JSON" ] || ! echo "$ASSETS_JSON" | grep -q '"assets":'; then
    echo "Error: Could not fetch assets for version $VERSION"
    exit 1
fi

ALL_ASSET_NAMES=$(echo "$ASSETS_JSON" | jq -r '.assets[].name')

for asset in $ALL_ASSET_NAMES; do
    # extract os and arch from asset name
    os="${asset#mysql-backup-}"
    os="${os%-*}"
    arch="${asset##*-}"
    echo "Processing $asset..."

    # ignore assets that are not linux or darwin
    if [[ "$os" != "linux" && "$os" != "darwin" ]]; then
        echo "  Skipping unsupported OS: $os"
        continue
    fi

    # get the json
    SINGLE_ASSET_JSON=$(echo "$ASSETS_JSON" | jq -r ".assets[] | select(.name==\"$asset\")")
    ASSET_URL=$(echo "$SINGLE_ASSET_JSON" | jq -r ".browser_download_url")
    ASSET_PATH="$TEMP_DIR/${asset}"
    
    echo "  Downloading $ASSET_URL..."
    if curl -L -f -o "$ASSET_PATH" "$ASSET_URL"; then
        # Calculate SHA256
        if command -v sha256sum >/dev/null 2>&1; then
            SHA256=$(sha256sum "$ASSET_PATH" | cut -d' ' -f1)
        elif command -v shasum >/dev/null 2>&1; then
            SHA256=$(shasum -a 256 "$ASSET_PATH" | cut -d' ' -f1)
        else
            echo "Error: Neither sha256sum nor shasum found"
            exit 1
        fi

        # Check expected sha256 from GitHub API
        EXPECTED_SHA256=$(echo "$SINGLE_ASSET_JSON" | jq -r ".digest")
        if [ -z "$EXPECTED_SHA256" ] || [ "$EXPECTED_SHA256" = "null" ]; then
            echo "  Warning: Expected sha256 not found in GitHub API for $asset"
            exit 1
        fi
        # may need to strip off leading "sha256:"
        EXPECTED_SHA256="${EXPECTED_SHA256#sha256:}"
        if [ "$SHA256" != "$EXPECTED_SHA256" ]; then
            echo "  Error: SHA256 mismatch for $asset"
            echo "    Calculated: $SHA256"
            echo "    Expected:   $EXPECTED_SHA256"
            exit 1
        else
            echo "  SHA256 matches expected value."
        fi

        # save the name value of the hash
        osucase="$(echo ${os} | tr 'a-z' 'A-Z')"
        archucase="$(echo ${arch} | tr 'a-z' 'A-Z')"
        eval "SHA256_${osucase}_${archucase}=${SHA256}"
        eval "ASSET_${osucase}_${archucase}=${ASSET_URL}"
    else
        echo "Error: Failed to download $asset!"
        exit 1
    fi
done

# Update the formula
echo "Updating formula file..."
cp "$FORMULA_FILE_TMPL" "$FORMULA_FILE_WORKING"

# Update SHA256 values for each platform
for var in $(set | awk -F= '/^SHA256_/ {print $1}'); do
    eval "sha256=\$$var"
    sed -i.tmp "s|${var}|${sha256}|g" "$FORMULA_FILE_WORKING"
done
for var in $(set | awk -F= '/^ASSET_/ {print $1}'); do
    eval "asset=\$$var"
    sed -i.tmp "s|${var}|${asset}|g" "$FORMULA_FILE_WORKING"
done

# Remove temporary sed files
rm -f "$FORMULA_FILE_WORKING.tmp"

# Show the changes
echo "Changes made to $FORMULA_FILE:"
diff "$FORMULA_FILE_WORKING" "$FORMULA_FILE" || true

# Cleanup
mv "$FORMULA_FILE_WORKING" "$FORMULA_FILE"
rm -rf "$TEMP_DIR"

echo ""
echo "Formula updated successfully!"
echo "Updated SHA256 checksums for platforms:"
for var in $(set | grep '^SHA256'); do
    echo "  $var"
done
echo ""
echo "Please review the changes and test the formula before committing:"
echo "  brew install --build-from-source ./$FORMULA_FILE"
echo "  brew test mysql-backup"
echo "  brew audit --strict mysql-backup"
echo ""
echo "To install from HEAD (build from source):"
echo "  brew install --HEAD mysql-backup"

# Homebrew Tap Contributing Guidelines

Thank you for your interest in contributing to the mysql-backup Homebrew tap!

## Formula Updates

When updating the mysql-backup formula, use the provided script `./scripts/update-formula.sh` to automate the process. For example, to updated to version `v1.2.3`, run:

```bash
./scripts/update-formula.sh v1.2.3
```

This script will:
1. Download pre-built binaries for all supported platforms
2. Calculate SHA256 checksums automatically
3. Update the formula with new version and checksums
4. Show you the changes for review

### Manual Updates

If you need to update manually:

1. **Version Updates**: Update the version number in all download URLs in `Formula/mysql-backup.rb`
2. **SHA256 Checksums**: Calculate and update SHA256 checksums for all platform binaries:
   - macOS Intel: `mysql-backup_darwin_amd64.tar.gz`
   - macOS Apple Silicon: `mysql-backup_darwin_arm64.tar.gz`
   - Linux x86_64: `mysql-backup_linux_amd64.tar.gz`
   - Linux ARM64: `mysql-backup_linux_arm64.tar.gz`
3. **Dependencies**: Review and update any dependencies if needed
4. **Testing**: Test both binary and HEAD installations

## Testing Your Changes

Before submitting changes, test both installation methods:

### Test Pre-built Binary Installation
```bash
# Install from your modified formula
brew install --verbose ./Formula/mysql-backup.rb

# Test the installation
brew test mysql-backup

# Audit for style and best practices
brew audit --strict mysql-backup

# Cleanup
brew uninstall mysql-backup
```

### Test HEAD Installation (Source Build)
```bash
# Install from HEAD (requires Go)
brew install --HEAD --verbose ./Formula/mysql-backup.rb

# Test the HEAD installation
brew test mysql-backup

# Cleanup
brew uninstall mysql-backup
```

## Calculating SHA256 Checksums

For each platform binary:

```bash
VERSION="vX.Y.Z" # update for correct version
# Download and calculate checksum
curl -L https://github.com/databacker/mysql-backup/releases/download/$VERSION/mysql-backup_darwin_amd64.tar.gz | sha256sum
curl -L https://github.com/databacker/mysql-backup/releases/download/$VERSION/mysql-backup_darwin_arm64.tar.gz | sha256sum
curl -L https://github.com/databacker/mysql-backup/releases/download/$VERSION/mysql-backup_linux_amd64.tar.gz | sha256sum
curl -L https://github.com/databacker/mysql-backup/releases/download/$VERSION/mysql-backup_linux_arm64.tar.gz | sha256sum
```

## Binary vs Source Installation

The formula supports two installation methods:

1. **Pre-built binaries** (default): Fast installation, no Go required
2. **HEAD/source build**: Latest code, requires Go toolchain

When contributing, ensure both methods work correctly.

## Pull Request Guidelines

1. Use the update script when possible for consistency
2. Test both binary and HEAD installations
3. Include a clear description of what was changed
4. Follow Homebrew's formula conventions
5. Update documentation if needed

## Questions?

If you have questions about contributing, please open an issue in this repository.

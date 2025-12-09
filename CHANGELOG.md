# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-12-09

### Added - Tool Expansion

#### New Programming Languages
- ✅ **PHP 8.2** with Composer and common extensions
  - MySQL, PostgreSQL, SQLite support
  - GD, Intl, BCMath extensions
  - Installed from Ondřej Surý PPA for latest version
- ✅ **Ruby** with rbenv version manager
  - System Ruby installation
  - rbenv for version management
  - ruby-build plugin included
  - Configured for both bash and zsh

#### New Databases
- ✅ **PostgreSQL 16** 
  - Official PostgreSQL repository
  - Auto-start on boot
  - Includes contrib packages
  - Setup instructions for initial configuration
- ✅ **MySQL** (latest stable)
  - Community server edition
  - Auto-start on boot
  - Includes mysql_secure_installation reminder
- ✅ **MongoDB 7.0**
  - Official MongoDB repository
  - Auto-start on boot
  - Running on default port 27017

#### New Productivity Applications
- ✅ **Discord** (via Flatpak)
  - Voice, video, and text communication
  - Latest stable version from Flathub
- ✅ **Microsoft Teams** (via Flatpak)
  - Collaboration and meeting platform
  - Latest version from Flathub
- ✅ **Outlook/Thunderbird**
  - Thunderbird as Outlook alternative
  - Exchange support via add-ons
  - Native Linux email client

### Enhanced
- Updated verification suite to include new tools
- Added configuration options in `config.example.yaml`
- Added version management in `versions.conf`
- Updated README with new tool documentation
- Expanded total installation functions from 14 to 22

### Statistics
- **Total Lines**: 1,881 (from 1,605)
- **Installation Functions**: 22 (from 14)
- **New Tools**: 8 (2 languages, 3 databases, 3 apps)

## [2.0.0] - 2025-12-09

### Added - Production-Ready Features

#### Security
- ✅ Checksum verification for all downloads (SHA256/SHA512)
- ✅ GPG signature verification support
- ✅ Automatic backup creation before system modifications
- ✅ Secure download-verify-execute pattern (no direct script piping)
- ✅ File integrity checks
- ✅ State tracking to prevent partial installations

#### Error Handling & Recovery
- ✅ Comprehensive error handling with rollback support
- ✅ Transaction logging for all operations
- ✅ State management with JSON state file
- ✅ Backup/restore functionality
- ✅ Cleanup for partial installations

#### Features
- ✅ Dry-run mode (`--dry-run`) to preview changes
- ✅ YAML configuration file support
- ✅ Installation profiles (minimal, developer, full)
- ✅ Platform detection and validation
- ✅ Architecture auto-detection (amd64, arm64)
- ✅ Post-installation verification suite
- ✅ Progress tracking with ETA
- ✅ Component listing (`--list`)
- ✅ Verification mode (`--verify`)
- ✅ Self-test mode (`--self-test`)
- ✅ Rollback support (`--rollback`)
- ✅ Version management via `versions.conf`

#### Code Quality
- ✅ Modular function structure
- ✅ Comprehensive documentation
- ✅ Bash 4+ requirement check
- ✅ Shellcheck compliance
- ✅ Consistent error handling patterns
- ✅ Input validation
- ✅ Detailed logging with multiple log files

#### Testing
- ✅ Test suite (`test/test-runner.sh`)
- ✅ Syntax validation
- ✅ Functional tests
- ✅ Self-test mode

#### Documentation
- ✅ Comprehensive README.md
- ✅ Example configuration file
- ✅ Contributing guidelines
- ✅ This changelog
- ✅ Inline code documentation

#### New Installation Functions
- ✅ Split cloud tools into individual functions:
  - `install_docker()`
  - `install_kubectl()`
  - `install_helm()`
  - `install_terraform()`
  - `install_aws_cli()`
  - `install_github_cli()`
- ✅ Each function properly tracked and verified

### Changed - Breaking Changes

#### Configuration
- **BREAKING**: Config file format changed to YAML (was simple key:value)
- **BREAKING**: New state directory: `/var/lib/popos-setup/`
- **BREAKING**: Backup directory: `~/.popos-setup-backups/` (configurable)
- **BREAKING**: Log directory: `./logs/` instead of current directory

#### Behavior
- Verification suite now runs automatically (can be skipped)
- Progress tracking is accurate and shows ETA
- All downloads require checksum verification by default
- Platform validation is mandatory

### Fixed

- ✅ Config file parsing now actually works (was defined but not used)
- ✅ Progress tracking calculation fixed
- ✅ Verification suite integrated into main flow
- ✅ Dependency resolution enforced
- ✅ Cloud tools properly tracked individually
- ✅ Consistent error handling across all functions

### Migration Guide from 1.x

1. **Update config file format**
   ```bash
   # Old format (simple key:value)
   install_docker: true
   
   # New format (YAML)
   cloud:
     docker: true
   ```

2. **Check new directories**
   - State: `/var/lib/popos-setup/state.json`
   - Backups: `~/.popos-setup-backups/`
   - Logs: `./logs/`

3. **New command-line options**
   ```bash
   # Preview changes before installing
   sudo ./setup.sh --dry-run
   
   # Verify existing installation
   sudo ./setup.sh --verify
   
   # List installed components
   sudo ./setup.sh --list
   ```

4. **Version management**
   - Tool versions now in `versions.conf`
   - Can override in config file

## [1.0.0] - Previous Version

### Initial Release
- Basic installation script
- Interactive prompts
- Common development tools
- Programming languages (Java, Go, Rust, Python, Node.js, .NET)
- IDEs (VS Code, Eclipse, Postman)
- Cloud tools (Docker, Kubernetes, Terraform, AWS, Azure)
- System tweaks
- ZSH setup
- Basic logging

### Known Issues in 1.0.0
- Config file parsing not implemented
- Progress tracking inaccurate
- Verification suite not integrated
- No checksum verification
- No rollback support
- No dry-run mode
- Cloud tools not individually tracked

---

## Version Numbering

- **Major version**: Breaking changes, significant new features
- **Minor version**: New features, backward compatible
- **Patch version**: Bug fixes, minor improvements

## Support

- **2.0.x**: Active development and support
- **1.0.x**: Security fixes only (deprecated)

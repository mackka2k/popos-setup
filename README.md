# Pop!_OS Developer Setup Script

A production-ready, enterprise-grade setup script for Pop!_OS and Ubuntu-based systems. Automates the installation and configuration of development tools, programming languages, IDEs, and system tweaks.

## Features

✅ **Production-Ready**
- Comprehensive error handling and rollback capability
- Checksum verification for all downloads
- GPG signature verification for critical tools
- Transaction-based installation with state tracking
- Automatic backup before system modifications

✅ **Flexible & Configurable**
- YAML-based configuration files
- Multiple installation profiles (minimal, developer, full)
- Interactive or fully automated modes
- Dry-run mode to preview changes

✅ **Comprehensive**
- 20+ programming languages and runtimes
- Popular IDEs (VS Code, Zed, Eclipse)
- Cloud tools (Docker, Kubernetes, Terraform, AWS, Azure)
- Security tools (YubiKey, USBGuard)
- System tweaks and optimizations

✅ **Safe & Reliable**
- Idempotent (safe to re-run)
- Platform detection and validation
- Dependency resolution
- Post-installation verification
- Detailed logging and progress tracking

## Quick Start

### Basic Installation (Interactive)

```bash
# Clone the repository
git clone <repository-url>
cd programmer-setup

# Run with interactive prompts
sudo ./setup.sh
```

### Automated Installation with Config

```bash
# Copy and customize the config file
cp config.example.yaml config.yaml
nano config.yaml

# Run with config file
sudo ./setup.sh --config config.yaml --yes
```

### Dry-Run Mode

```bash
# Preview what will be installed without making changes
sudo ./setup.sh --dry-run --config config.yaml
```

## Usage

```bash
sudo ./setup.sh [OPTIONS]

Options:
  -y, --yes              Auto-approve all prompts (non-interactive mode)
  -c, --config FILE      Use configuration file
  -n, --dry-run          Preview changes without installing
  -p, --profile PROFILE  Use installation profile (minimal|developer|full)
  -b, --backup           Create backup before installation
  -r, --restore FILE     Restore from backup
  -u, --uninstall        Uninstall components
  -l, --list             List installed components
  -v, --verify           Verify installed components
  --update               Update installed tools to latest versions
  --self-test            Run self-tests
  --rollback             Rollback last installation
  -h, --help             Show help message
```

## Installation Profiles

### Minimal
- System updates and common tools only
- Git, build-essential, curl, wget
- No programming languages or IDEs

### Developer (Default)
- All common development tools
- Popular languages: Python, Node.js, Go, Rust
- VS Code editor
- Docker and basic cloud tools
- ZSH with Oh-My-ZSH

### Full
- Everything in Developer profile
- Additional languages: Java, .NET
- Multiple IDEs: Eclipse, Zed
- All cloud tools: AWS, Azure, GCloud
- Security tools: YubiKey, USBGuard
- Virtualization: KVM/VirtualBox
- Media tools and themes

## Configuration

The script uses a YAML configuration file for non-interactive installations. See [config.example.yaml](config.example.yaml) for all available options.

### Example Configuration

```yaml
profile: developer

languages:
  python: true
  nodejs: true
  go: true
  rust: false

ides:
  vscode: true
  eclipse: false

cloud:
  docker: true
  kubectl: true
  terraform: true
```

## What Gets Installed

### Programming Languages
- **Java**: OpenJDK 17 + Maven
- **Go**: Latest stable (configurable)
- **Rust**: Via rustup
- **Python**: Python 3 + pip
- **Node.js**: LTS version 20
- **.NET**: SDK 8.0
- **PHP**: 8.2 with Composer
- **Ruby**: Latest with rbenv

### Databases
- **PostgreSQL**: Version 16
- **MySQL**: Latest stable
- **MongoDB**: Version 7.0

### IDEs & Editors
- **VS Code**: Latest stable
- **Zed**: Modern editor
- **Eclipse**: Java IDE (via Flatpak)
- **Postman**: API testing

### Cloud & DevOps
- **Docker**: Container runtime + Docker Compose
- **Podman**: Docker alternative
- **Kubernetes**: kubectl + Helm
- **Terraform**: Infrastructure as Code
- **AWS CLI**: Amazon Web Services
- **Azure CLI**: Microsoft Azure
- **GitHub CLI**: gh command

### Development Tools
- build-essential, make, cmake
- Git with recommended config
- Modern CLI tools: fzf, ripgrep, bat, exa, fd, zoxide
- htop, neofetch, vim, tmux, jq, yq

### Shell & Terminal
- ZSH with Oh-My-ZSH
- Syntax highlighting
- Useful plugins (git, docker, kubectl, etc.)
- Tilix terminal

### Security
- YubiKey support (PAM, manager)
- USBGuard (USB device control)
- SSH key setup assistance
- GPG key setup assistance

### Productivity Apps
- **Discord**: Voice, video, and text chat
- **Microsoft Teams**: Collaboration platform
- **Outlook**: Email client (Thunderbird with Exchange support)

### System Tweaks
- Increased inotify watch limit
- Font rendering optimizations
- GNOME tweaks and extensions
- Theme support

## Safety Features

### Automatic Backups
Before making system changes, the script creates backups:
- Configuration files → `~/.popos-setup-backups/`
- State tracking → `/var/lib/popos-setup/state.json`
- Installation logs → `./logs/`

### Rollback Support
If an installation fails, you can rollback:
```bash
sudo ./setup.sh --rollback
```

### Verification
After installation, verify all components:
```bash
sudo ./setup.sh --verify
```

## Logs

All operations are logged:
- **Installation log**: `setup_log_YYYY-MM-DD_HH:MM:SS.log`
- **Verification log**: `verification_YYYY-MM-DD_HH:MM:SS.log`
- **State file**: `/var/lib/popos-setup/state.json`

## Version Management

Tool versions are managed in `versions.conf`. You can:
- Update versions centrally
- Override in config file
- Automatic checksum verification

## Platform Support

- **Pop!_OS**: 22.04 LTS (primary)
- **Ubuntu**: 22.04 LTS, 24.04 LTS
- **Architecture**: amd64, arm64 (auto-detected)

## Troubleshooting

### Script fails with "Platform not supported"
The script detected an incompatible OS. Currently supports Pop!_OS and Ubuntu 22.04+.

### Installation fails mid-way
Check the log file for errors. Use `--rollback` to undo changes:
```bash
sudo ./setup.sh --rollback
```

### Checksum verification fails
This means the downloaded file doesn't match the expected checksum. This is a security feature. Check:
1. Your internet connection
2. The versions.conf file has correct checksums
3. Try again (download may have been corrupted)

### Docker/Kubernetes tools not working
You may need to log out and back in for group membership changes to take effect.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Adding new tools
- Testing requirements
- Code style
- Submitting pull requests

## Security

- All downloads are verified with checksums
- GPG signatures verified for critical tools
- No scripts piped directly to shell without verification
- Minimal use of sudo within functions
- State tracking prevents partial installations

## License

MIT License - See LICENSE file for details

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and migration guides.

## Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: This README + inline comments

## Acknowledgments

Based on the excellent Pop!_OS setup guide and community contributions.

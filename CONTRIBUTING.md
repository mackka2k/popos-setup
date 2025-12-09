# Contributing to Pop!_OS Setup Script

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS version, architecture)
   - Relevant log files

### Suggesting Enhancements

1. Check existing issues and discussions
2. Create an issue describing:
   - The enhancement and its benefits
   - Potential implementation approach
   - Any breaking changes

### Adding New Tools

To add a new tool to the installation script:

1. **Create installation function**
   ```bash
   install_newtool() {
       log_info "Installing NewTool..."
       
       if [ "$DRY_RUN" = true ]; then
           log_info "[DRY-RUN] Would install NewTool"
           update_progress
           return 0
       fi
       
       if ! check_command newtool; then
           # Installation steps here
           apt install -y newtool
           log_success "NewTool installed"
       else
           log_info "NewTool already installed"
       fi
       
       mark_installed "newtool" "$(newtool --version)"
       update_progress
   }
   ```

2. **Add to versions.conf** (if applicable)
   ```bash
   NEWTOOL_VERSION=1.0.0
   NEWTOOL_CHECKSUM=sha256:abc123...
   ```

3. **Add to config.example.yaml**
   ```yaml
   tools:
     newtool: true
   ```

4. **Add verification**
   ```bash
   if [ "${INSTALLED_COMPONENTS[newtool]:-false}" = "true" ]; then
       verify_installation "NewTool" "newtool" "version" || ((failed++))
   fi
   ```

5. **Update documentation**
   - Add to README.md
   - Update CHANGELOG.md

### Code Style

- Use `shellcheck` to validate scripts
- Follow existing code structure and naming conventions
- Add comments for complex logic
- Use meaningful variable names
- Prefer `[[` over `[` for conditionals
- Quote all variables: `"$var"` not `$var`
- Use `readonly` for constants
- Use `local` for function variables

### Function Documentation

Document functions with:
```bash
################################################################################
# Function Name
# Description: What the function does
# Arguments:
#   $1 - First argument description
#   $2 - Second argument description
# Returns:
#   0 on success, 1 on failure
# Side Effects:
#   What the function modifies
################################################################################
function_name() {
    # Implementation
}
```

### Testing Requirements

Before submitting a PR:

1. **Run tests**
   ```bash
   cd test
   chmod +x test-runner.sh
   ./test-runner.sh
   ```

2. **Run shellcheck**
   ```bash
   shellcheck setup.sh
   ```

3. **Test in dry-run mode**
   ```bash
   sudo ./setup.sh --dry-run --yes
   ```

4. **Test on clean VM**
   - Pop!_OS 22.04
   - Ubuntu 22.04 or 24.04

5. **Verify installation**
   ```bash
   sudo ./setup.sh --verify
   ```

### Pull Request Process

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. **Make your changes**
   - Follow code style guidelines
   - Add tests if applicable
   - Update documentation

4. **Commit your changes**
   ```bash
   git commit -m "Add feature: description"
   ```
   
   Commit message format:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for updates to existing features
   - `Docs:` for documentation changes
   - `Test:` for test additions/changes

5. **Push to your fork**
   ```bash
   git push origin feature/my-new-feature
   ```

6. **Create Pull Request**
   - Provide clear description
   - Reference related issues
   - Include test results
   - Add screenshots if UI-related

### Review Process

- Maintainers will review your PR
- Address any feedback
- Once approved, PR will be merged
- Your contribution will be credited

## Development Setup

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd programmer-setup
   ```

2. **Install development tools**
   ```bash
   sudo apt install shellcheck
   ```

3. **Make scripts executable**
   ```bash
   chmod +x setup.sh test/test-runner.sh
   ```

## Security

- Never commit sensitive information
- Verify checksums for all downloads
- Use HTTPS for all external resources
- Avoid piping scripts directly to shell
- Validate all user inputs

## Questions?

- Open a Discussion for questions
- Check existing Issues and Discussions
- Read the README.md thoroughly

Thank you for contributing! 🎉

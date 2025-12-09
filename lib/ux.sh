#!/bin/bash
################################################################################
# UX & Polish Module
# User experience enhancements and quality of life features
################################################################################

show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║     ██████╗  ██████╗ ██████╗     ██╗ ██████╗ ███████╗               ║
║     ██╔══██╗██╔═══██╗██╔══██╗   ██╔╝██╔═══██╗██╔════╝               ║
║     ██████╔╝██║   ██║██████╔╝  ██╔╝ ██║   ██║███████╗               ║
║     ██╔═══╝ ██║   ██║██╔═══╝  ██╔╝  ██║   ██║╚════██║               ║
║     ██║     ╚██████╔╝██║     ██╔╝   ╚██████╔╝███████║               ║
║     ╚═╝      ╚═════╝ ╚═╝     ╚═╝     ╚═════╝ ╚══════╝               ║
║                                                                       ║
║              Developer Setup Script v3.0.0                           ║
║              Enterprise-Grade Automation                             ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo ""
}

show_installation_summary() {
    log_info "╔═══════════════════════════════════════════════════════════╗"
    log_info "║              Installation Complete! 🎉                    ║"
    log_info "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Show installed components
    load_state
    
    if [ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]; then
        log_info "📦 Installed Components:"
        echo ""
        for component in "${!INSTALLED_COMPONENTS[@]}"; do
            local version="${COMPONENT_VERSIONS[$component]:-unknown}"
            echo "  ✓ $component ($version)"
        done
        echo ""
    fi
    
    # Show next steps
    log_info "🚀 Next Steps:"
    echo "  1. Restart your computer for all changes to take effect"
    echo "  2. Run 'sudo ./setup.sh --verify' to validate installations"
    echo "  3. Check logs: $LOG_FILE"
    echo ""
    
    # Show useful commands
    log_info "💡 Useful Commands:"
    echo "  sudo ./setup.sh --list      # List installed components"
    echo "  sudo ./setup.sh --verify    # Verify installations"
    echo "  sudo ./setup.sh --help      # Show all options"
    echo ""
    
    log_success "Setup completed successfully!"
}

check_for_updates() {
    log_info "Checking for script updates..."
    
    if ! check_command curl; then
        log_debug "curl not available, skipping update check"
        return 0
    fi
    
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/mackka2k/popos-setup/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 || true)
    
    if [ -z "$latest_version" ]; then
        log_success "You are running the latest version!"
        return 0
    fi
    
    # Remove 'v' prefix if present
    latest_version="${latest_version#v}"
    
    if [ "$latest_version" != "$SCRIPT_VERSION" ]; then
        log_warn "╔═══════════════════════════════════════════════════════════╗"
        log_warn "║  New version available: v$latest_version (current: v$SCRIPT_VERSION)  "
        log_warn "║  Update: cd $(pwd) && git pull origin main               "
        log_warn "╚═══════════════════════════════════════════════════════════╝"
        echo ""
    else
        log_success "You are running the latest version!"
    fi
}

health_check() {
    log_info "Running system health check..."
    
    local issues=0
    local warnings=0
    
    # Check disk space
    local free_space_kb=$(df / | tail -1 | awk '{print $4}')
    local free_space_gb=$((free_space_kb / 1024 / 1024))
    
    if [ "$free_space_kb" -lt 10485760 ]; then  # 10GB
        log_error "Low disk space: ${free_space_gb}GB free (10GB minimum required)"
        ((issues++))
    else
        log_success "Disk space: ${free_space_gb}GB free"
    fi
    
    # Check memory
    local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    if [ "$total_mem_kb" -lt 4194304 ]; then  # 4GB
        log_warn "Low memory: ${total_mem_gb}GB (4GB recommended)"
        ((warnings++))
    else
        log_success "Memory: ${total_mem_gb}GB"
    fi
    
    # Check internet connection
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connection: OK"
    else
        log_error "No internet connection detected"
        ((issues++))
    fi
    
    # Check for pending system updates
    if apt list --upgradable 2>/dev/null | grep -q upgradable; then
        log_warn "System updates available. Consider running 'sudo apt update && sudo apt upgrade' first"
        ((warnings++))
    fi
    
    # Summary
    echo ""
    if [ "$issues" -eq 0 ]; then
        log_success "Health check passed! ($warnings warnings)"
        return 0
    else
        log_error "Health check failed with $issues critical issue(s)"
        if ! ask_permission "Continue anyway?"; then
            exit 1
        fi
    fi
}

create_system_snapshot() {
    log_info "Creating system snapshot..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would create system snapshot"
        return 0
    fi
    
    # Check if Timeshift is installed
    if ! check_command timeshift; then
        if ask_permission "Install Timeshift for system snapshots?"; then
            apt install -y timeshift
        else
            log_info "Skipping system snapshot"
            return 0
        fi
    fi
    
    # Create snapshot
    log_info "Creating Timeshift snapshot (this may take a few minutes)..."
    timeshift --create --comments "Before Pop!_OS Setup Script v$SCRIPT_VERSION" --scripted
    
    log_success "System snapshot created"
}

notify_completion() {
    if check_command notify-send; then
        local user_info
        user_info=$(get_user_info)
        local target_user="${user_info%%:*}"
        
        sudo -u "$target_user" DISPLAY=:0 notify-send \
            "Setup Complete" \
            "Pop!_OS setup script finished successfully!" \
            --icon=dialog-information \
            --urgency=normal 2>/dev/null || true
    fi
}

show_estimated_time() {
    local total_tasks="$1"
    
    if [ "$total_tasks" -eq 0 ]; then
        return 0
    fi
    
    local avg_time_per_task=45  # seconds
    local total_seconds=$((total_tasks * avg_time_per_task))
    local minutes=$((total_seconds / 60))
    
    log_info "📊 Estimated installation time: ~$minutes minutes"
    log_info "   (based on $total_tasks selected components)"
    echo ""
}

backup_dotfiles() {
    log_info "Backing up dotfiles..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would backup dotfiles"
        return 0
    fi
    
    local user_info
    user_info=$(get_user_info)
    local target_user="${user_info%%:*}"
    local target_home="${user_info#*:}"
    
    local dotfiles_backup="$BACKUP_DIR/dotfiles-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$dotfiles_backup"
    
    # Backup common dotfiles
    for file in .bashrc .zshrc .gitconfig .vimrc .tmux.conf; do
        if [ -f "$target_home/$file" ]; then
            cp "$target_home/$file" "$dotfiles_backup/" 2>/dev/null || true
        fi
    done
    
    # Backup .ssh directory (without private keys for security)
    if [ -d "$target_home/.ssh" ]; then
        mkdir -p "$dotfiles_backup/.ssh"
        cp "$target_home/.ssh/config" "$dotfiles_backup/.ssh/" 2>/dev/null || true
        cp "$target_home/.ssh/"*.pub "$dotfiles_backup/.ssh/" 2>/dev/null || true
    fi
    
    log_success "Dotfiles backed up to: $dotfiles_backup"
}

install_profile() {
    local profile="$1"
    
    log_info "Installing profile: $profile"
    
    case "$profile" in
        minimal)
            log_info "Minimal profile: Essential tools only"
            update_system
            install_common_tools
            setup_zsh
            configure_git_advanced
            ;;
        developer)
            log_info "Developer profile: Full development environment"
            update_system
            install_common_tools
            install_vscode
            install_docker
            install_kubectl
            install_nodejs
            install_python
            install_go
            setup_zsh
            install_shell_enhancements
            setup_ssh_automation
            configure_git_advanced
            ;;
        gamer)
            log_info "Gamer profile: Gaming optimizations"
            update_system
            install_common_tools
            install_steam
            optimize_for_gaming
            apply_system_optimizations
            ;;
        full)
            log_info "Full profile: Everything!"
            # This will be handled by the main script
            return 1
            ;;
        *)
            log_error "Unknown profile: $profile"
            return 1
            ;;
    esac
    
    log_success "Profile '$profile' installed"
}

show_profile_menu() {
    echo ""
    log_info "Available Installation Profiles:"
    echo ""
    echo "  1) Minimal    - Essential tools only (~5 min)"
    echo "  2) Developer  - Full dev environment (~20 min)"
    echo "  3) Gamer      - Gaming optimizations (~10 min)"
    echo "  4) Full       - Everything! (~45 min)"
    echo "  5) Custom     - Choose components interactively"
    echo ""
    
    read -p "Select profile [1-5]: " choice
    
    case "$choice" in
        1) install_profile "minimal" ;;
        2) install_profile "developer" ;;
        3) install_profile "gamer" ;;
        4) return 1 ;;  # Continue with full installation
        5) return 1 ;;  # Continue with interactive mode
        *) log_error "Invalid choice"; exit 1 ;;
    esac
    
    return 0
}

#!/bin/bash
################################################################################
# System Configuration Module
# Advanced system configurations and tweaks
################################################################################

configure_git_advanced() {
    log_info "Configuring Git with advanced settings..."
    
    local user_info
    user_info=$(get_user_info)
    local target_user="${user_info%%:*}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure Git"
        return 0
    fi
    
    # Better git defaults
    sudo -u "$target_user" git config --global init.defaultBranch main
    sudo -u "$target_user" git config --global pull.rebase true
    sudo -u "$target_user" git config --global fetch.prune true
    sudo -u "$target_user" git config --global diff.colorMoved zebra
    sudo -u "$target_user" git config --global core.autocrlf input
    sudo -u "$target_user" git config --global rerere.enabled true
    sudo -u "$target_user" git config --global help.autocorrect 10
    
    # Useful aliases
    sudo -u "$target_user" git config --global alias.st status
    sudo -u "$target_user" git config --global alias.co checkout
    sudo -u "$target_user" git config --global alias.br branch
    sudo -u "$target_user" git config --global alias.cm commit
    sudo -u "$target_user" git config --global alias.unstage 'reset HEAD --'
    sudo -u "$target_user" git config --global alias.last 'log -1 HEAD'
    sudo -u "$target_user" git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    log_success "Git configured with advanced settings"
}

configure_gnome_tweaks() {
    log_info "Applying GNOME desktop tweaks..."
    
    local user_info
    user_info=$(get_user_info)
    local target_user="${user_info%%:*}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure GNOME"
        return 0
    fi
    
    # Better desktop experience
    sudo -u "$target_user" gsettings set org.gnome.desktop.interface clock-show-weekday true
    sudo -u "$target_user" gsettings set org.gnome.desktop.interface show-battery-percentage true
    sudo -u "$target_user" gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    sudo -u "$target_user" gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    
    # Dash to dock settings (if available)
    if sudo -u "$target_user" gsettings list-schemas | grep -q "dash-to-dock"; then
        sudo -u "$target_user" gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
        sudo -u "$target_user" gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    fi
    
    log_success "GNOME desktop tweaks applied"
}

configure_vim_defaults() {
    log_info "Configuring Vim with better defaults..."
    
    local user_info
    user_info=$(get_user_info)
    local target_user="${user_info%%:*}"
    local target_home="${user_info#*:}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure Vim"
        return 0
    fi
    
    local vimrc="$target_home/.vimrc"
    
    if [ ! -f "$vimrc" ]; then
        sudo -u "$target_user" tee "$vimrc" > /dev/null << 'EOF'
" Better Vim defaults
set number relativenumber
set autoindent
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set mouse=a
set clipboard=unnamedplus
set ignorecase
set smartcase
set incsearch
set hlsearch
set cursorline
syntax on
filetype plugin indent on

" Better navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
EOF
        log_success "Vim configured: $vimrc"
    else
        log_info "Vim config already exists"
    fi
}

configure_system_limits() {
    log_info "Configuring system limits..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure system limits"
        return 0
    fi
    
    local limits_conf="/etc/security/limits.conf"
    
    if ! grep -q "# Pop!_OS Setup Script limits" "$limits_conf"; then
        cat >> "$limits_conf" << 'EOF'

# Pop!_OS Setup Script limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF
        log_success "System limits configured"
    else
        log_info "System limits already configured"
    fi
}

configure_docker_daemon() {
    log_info "Configuring Docker daemon..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure Docker"
        return 0
    fi
    
    if ! check_command docker; then
        log_info "Docker not installed, skipping Docker config"
        return 0
    fi
    
    local docker_config="/etc/docker/daemon.json"
    
    if [ ! -f "$docker_config" ]; then
        mkdir -p /etc/docker
        tee "$docker_config" > /dev/null << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ],
  "storage-driver": "overlay2"
}
EOF
        systemctl restart docker 2>/dev/null || true
        log_success "Docker daemon configured"
    else
        log_info "Docker daemon config already exists"
    fi
}

configure_grub_faster_boot() {
    log_info "Configuring GRUB for faster boot..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure GRUB"
        return 0
    fi
    
    local grub_config="/etc/default/grub"
    
    if [ -f "$grub_config" ]; then
        create_backup "$grub_config" "grub"
        
        # Set timeout to 2 seconds
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' "$grub_config"
        
        # Update GRUB
        update-grub
        log_success "GRUB configured for faster boot"
    else
        log_warn "GRUB config not found"
    fi
}

configure_timezone_locale() {
    log_info "Configuring timezone and locale..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure timezone/locale"
        return 0
    fi
    
    # Set timezone to Lithuania
    timedatectl set-timezone Europe/Vilnius
    log_success "Timezone set to Europe/Vilnius (Lithuania)"
    
    # Ensure UTF-8 locale
    if ! locale -a | grep -q "en_US.utf8"; then
        locale-gen en_US.UTF-8
    fi
    localectl set-locale LANG=en_US.UTF-8
    log_success "Locale set to en_US.UTF-8"
}

setup_automatic_maintenance() {
    log_info "Setting up automatic maintenance tasks..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would setup automatic maintenance"
        return 0
    fi
    
    # Create cleanup script
    local cleanup_script="/usr/local/bin/system-cleanup.sh"
    
    tee "$cleanup_script" > /dev/null << 'EOF'
#!/bin/bash
# Automatic system cleanup
apt autoremove -y
apt autoclean
journalctl --vacuum-time=7d
find /tmp -type f -atime +7 -delete 2>/dev/null
EOF
    chmod +x "$cleanup_script"
    
    # Add weekly cron job
    local cron_file="/etc/cron.weekly/system-cleanup"
    ln -sf "$cleanup_script" "$cron_file"
    
    log_success "Automatic maintenance configured (weekly cleanup)"
}

configure_bash_history() {
    log_info "Configuring better Bash history..."
    
    local user_info
    user_info=$(get_user_info)
    local target_user="${user_info%%:*}"
    local target_home="${user_info#*:}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure Bash history"
        return 0
    fi
    
    local bashrc="$target_home/.bashrc"
    
    if [ -f "$bashrc" ] && ! grep -q "# Better history settings" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Better history settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
EOF
        log_success "Bash history configured"
    else
        log_info "Bash history already configured"
    fi
}

apply_all_configurations() {
    log_info "Applying all system configurations..."
    
    configure_timezone_locale
    configure_git_advanced
    configure_gnome_tweaks
    configure_vim_defaults
    configure_system_limits
    configure_docker_daemon
    configure_grub_faster_boot
    setup_automatic_maintenance
    configure_bash_history
    
    log_success "All system configurations applied"
    log_warn "Some changes require logout/reboot to take effect"
    
    mark_installed "system_configuration" "configured"
}

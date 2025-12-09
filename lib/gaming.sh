#!/bin/bash
################################################################################
# Gaming Optimization Module
# NVIDIA GPU optimization and gaming performance tweaks
################################################################################

detect_nvidia_gpu() {
    if lspci | grep -i nvidia > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

install_gamemode() {
    log_info "Installing GameMode..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install GameMode"
        return 0
    fi
    
    if ! check_command gamemoded; then
        apt update
        apt install -y gamemode
        log_success "GameMode installed"
        log_info "Games will automatically use GameMode when launched"
    else
        log_info "GameMode already installed"
    fi
}

configure_nvidia_performance() {
    log_info "Configuring NVIDIA for maximum performance..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure NVIDIA"
        return 0
    fi
    
    if ! detect_nvidia_gpu; then
        log_info "No NVIDIA GPU detected, skipping NVIDIA configuration"
        return 0
    fi
    
    # Configure NVIDIA settings if nvidia-settings is available
    if check_command nvidia-settings; then
        log_info "Applying NVIDIA performance settings..."
        
        # Maximum performance mode
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" >/dev/null 2>&1 || true
        nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1" >/dev/null 2>&1 || true
        nvidia-settings -a "[gpu:0]/PowerMizerEnable=1" >/dev/null 2>&1 || true
        
        # Disable VSync for better FPS
        nvidia-settings -a "SyncToVBlank=0" >/dev/null 2>&1 || true
        nvidia-settings -a "AllowFlipping=1" >/dev/null 2>&1 || true
        
        log_success "NVIDIA performance settings applied"
    else
        log_warn "nvidia-settings not found. Install NVIDIA drivers first."
    fi
}

set_cpu_performance_mode() {
    log_info "Setting CPU to performance mode..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would set CPU performance mode"
        return 0
    fi
    
    # Install cpufrequtils if not present
    if ! check_command cpufreq-set; then
        apt install -y cpufrequtils
    fi
    
    # Set all CPUs to performance governor
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "performance" > "$cpu" 2>/dev/null || true
        fi
    done
    
    # Also use cpufreq-set as backup
    cpufreq-set -g performance 2>/dev/null || true
    
    log_success "CPU set to performance mode"
    log_info "Note: This will reset on reboot. For permanent change, use system optimization module."
}

clear_shader_cache() {
    log_info "Clearing shader cache..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would clear shader cache"
        return 0
    fi
    
    local user_info
    user_info=$(get_user_info)
    local target_user="${user_info%%:*}"
    local target_home="${user_info#*:}"
    
    # Clear various shader caches
    sudo -u "$target_user" rm -rf "$target_home/.cache/"*shader* 2>/dev/null || true
    sudo -u "$target_user" rm -rf "$target_home/.cache/mesa_shader_cache" 2>/dev/null || true
    sudo -u "$target_user" rm -rf "$target_home/.nv/GLCache" 2>/dev/null || true
    
    log_success "Shader cache cleared"
}

install_nvidia_drivers() {
    log_info "Installing NVIDIA drivers..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install NVIDIA drivers"
        return 0
    fi
    
    if ! detect_nvidia_gpu; then
        log_info "No NVIDIA GPU detected, skipping driver installation"
        return 0
    fi
    
    # Check if drivers already installed
    if check_command nvidia-smi; then
        log_info "NVIDIA drivers already installed"
        nvidia-smi --query-gpu=driver_version --format=csv,noheader
        return 0
    fi
    
    # Install NVIDIA drivers
    if check_command system76-power; then
        # Pop!_OS has its own driver management
        log_info "Installing NVIDIA drivers via system76-power..."
        apt install -y system76-driver-nvidia
    else
        # Ubuntu/other distros
        log_info "Installing NVIDIA drivers..."
        ubuntu-drivers devices
        ubuntu-drivers autoinstall
    fi
    
    log_success "NVIDIA drivers installed"
    log_warn "Reboot required for NVIDIA drivers to take effect"
}

optimize_for_gaming() {
    log_info "Applying gaming optimizations..."
    
    # Detect GPU
    if detect_nvidia_gpu; then
        log_info "NVIDIA GPU detected!"
        
        if ask_permission "Install NVIDIA drivers (if not already installed)?"; then
            install_nvidia_drivers
        fi
        
        if ask_permission "Apply NVIDIA performance optimizations?"; then
            configure_nvidia_performance
        fi
    else
        log_info "No NVIDIA GPU detected (AMD/Intel GPU)"
    fi
    
    # Install GameMode (works with all GPUs)
    if ask_permission "Install GameMode for better gaming performance?"; then
        install_gamemode
    fi
    
    # CPU performance mode
    if ask_permission "Set CPU to performance mode?"; then
        set_cpu_performance_mode
    fi
    
    # Clear shader cache
    if ask_permission "Clear shader cache?"; then
        clear_shader_cache
    fi
    
    log_success "Gaming optimizations complete"
    log_warn "Restart your PC for all changes to take effect"
    
    mark_installed "gaming_optimization" "configured"
}

#!/bin/bash
################################################################################
# System Optimization Module
# Performance tweaks and system optimizations
################################################################################

optimize_swap() {
    log_info "Optimizing swap configuration..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would optimize swap"
        return 0
    fi
    
    # Set swappiness to 10 (default is 60)
    # Lower values reduce swap usage, better for systems with sufficient RAM
    local swappiness=10
    
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=$swappiness" >> /etc/sysctl.conf
        sysctl -w vm.swappiness=$swappiness
        log_success "Swappiness set to $swappiness"
    else
        log_info "Swappiness already configured"
    fi
    
    # Set vfs_cache_pressure (default is 100)
    # Lower values preserve cache, better for desktop systems
    local cache_pressure=50
    
    if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then
        echo "vm.vfs_cache_pressure=$cache_pressure" >> /etc/sysctl.conf
        sysctl -w vm.vfs_cache_pressure=$cache_pressure
        log_success "VFS cache pressure set to $cache_pressure"
    else
        log_info "VFS cache pressure already configured"
    fi
}

optimize_io_scheduler() {
    log_info "Optimizing I/O scheduler..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would optimize I/O scheduler"
        return 0
    fi
    
    # Detect if we have SSDs
    local has_ssd=false
    for disk in /sys/block/sd*/queue/rotational; do
        if [ -f "$disk" ] && [ "$(cat "$disk")" = "0" ]; then
            has_ssd=true
            break
        fi
    done
    
    if [ "$has_ssd" = true ]; then
        log_info "SSD detected, setting optimal scheduler..."
        
        # For SSDs, use mq-deadline or none
        for disk in /sys/block/sd*; do
            if [ -f "$disk/queue/rotational" ] && [ "$(cat "$disk/queue/rotational")" = "0" ]; then
                local disk_name=$(basename "$disk")
                
                # Check available schedulers
                if [ -f "$disk/queue/scheduler" ]; then
                    if grep -q "mq-deadline" "$disk/queue/scheduler"; then
                        echo "mq-deadline" > "$disk/queue/scheduler"
                        log_success "Set mq-deadline scheduler for $disk_name"
                    elif grep -q "none" "$disk/queue/scheduler"; then
                        echo "none" > "$disk/queue/scheduler"
                        log_success "Set none scheduler for $disk_name"
                    fi
                fi
            fi
        done
    else
        log_info "HDD detected, using default scheduler"
    fi
}

optimize_filesystem() {
    log_info "Optimizing filesystem mounts..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would optimize filesystem"
        return 0
    fi
    
    # Check if noatime is already set
    if mount | grep -q "noatime"; then
        log_info "noatime already configured"
    else
        log_warn "Consider adding 'noatime' to /etc/fstab for better performance"
        log_info "This reduces disk writes by not updating access times"
        log_info "Example: UUID=xxx / ext4 defaults,noatime 0 1"
    fi
}

optimize_network() {
    log_info "Optimizing network settings..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would optimize network"
        return 0
    fi
    
    # TCP optimization
    if ! grep -q "net.core.default_qdisc" /etc/sysctl.conf; then
        cat >> /etc/sysctl.conf << 'EOF'

# Network optimizations
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.core.netdev_max_backlog=5000
net.core.rmem_max=16777216
net.core.wmem_max=16777216
EOF
        sysctl -p
        log_success "Network optimizations applied"
    else
        log_info "Network optimizations already configured"
    fi
}

optimize_ssd() {
    log_info "Applying SSD-specific optimizations..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would optimize for SSD"
        return 0
    fi
    
    # Enable TRIM for SSDs
    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
        log_info "TRIM already enabled"
    else
        systemctl enable fstrim.timer
        systemctl start fstrim.timer
        log_success "TRIM enabled for SSDs"
    fi
}

apply_system_optimizations() {
    log_info "Applying system optimizations..."
    
    # Backup sysctl.conf
    create_backup "/etc/sysctl.conf" "sysctl.conf"
    
    optimize_swap
    optimize_io_scheduler
    optimize_filesystem
    optimize_network
    optimize_ssd
    
    log_success "System optimizations complete"
    log_warn "Some optimizations require a reboot to take full effect"
    
    mark_installed "system_optimization" "configured"
}

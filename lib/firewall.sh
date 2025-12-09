#!/bin/bash
################################################################################
# Firewall Configuration Module
# UFW setup and configuration
################################################################################

setup_ufw() {
    log_info "Setting up UFW firewall..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would setup UFW"
        return 0
    fi
    
    # Install UFW if not present
    if ! check_command ufw; then
        apt install -y ufw
    fi
    
    # Reset to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    log_success "UFW default policies set"
}

configure_firewall_rules() {
    log_info "Configuring firewall rules..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure firewall rules"
        return 0
    fi
    
    # Allow SSH
    ufw allow 22/tcp comment 'SSH'
    log_info "Allowed: SSH (22/tcp)"
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    log_info "Allowed: HTTP (80/tcp), HTTPS (443/tcp)"
    
    # Allow common development ports (optional)
    if ask_permission "Allow common development ports (3000, 8080, 5000)?"; then
        ufw allow 3000/tcp comment 'Dev Server'
        ufw allow 8080/tcp comment 'Alt HTTP'
        ufw allow 5000/tcp comment 'Flask/Dev'
        log_info "Allowed: Development ports"
    fi
    
    log_success "Firewall rules configured"
}

enable_rate_limiting() {
    log_info "Enabling SSH rate limiting..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would enable rate limiting"
        return 0
    fi
    
    # Remove existing SSH rule
    ufw delete allow 22/tcp 2>/dev/null || true
    
    # Add rate-limited SSH rule
    ufw limit 22/tcp comment 'SSH with rate limiting'
    
    log_success "SSH rate limiting enabled (max 6 connections per 30 seconds)"
}

configure_docker_firewall() {
    log_info "Configuring Docker firewall integration..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure Docker firewall"
        return 0
    fi
    
    # Check if Docker is installed
    if ! check_command docker; then
        log_info "Docker not installed, skipping Docker firewall config"
        return 0
    fi
    
    # Configure UFW to work with Docker
    local ufw_after="/etc/ufw/after.rules"
    
    if [ -f "$ufw_after" ]; then
        create_backup "$ufw_after" "ufw-after.rules"
        
        if ! grep -q "# BEGIN UFW AND DOCKER" "$ufw_after"; then
            cat >> "$ufw_after" << 'EOF'

# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
EOF
            log_success "Docker firewall integration configured"
        else
            log_info "Docker firewall integration already configured"
        fi
    fi
}

enable_firewall() {
    log_info "Enabling firewall..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would enable firewall"
        return 0
    fi
    
    # Enable UFW
    ufw --force enable
    
    # Enable UFW service
    systemctl enable ufw
    
    log_success "Firewall enabled and will start on boot"
    
    # Show status
    echo ""
    ufw status verbose
    echo ""
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    if ! ask_permission "Setup and enable UFW firewall?"; then
        log_info "Skipping firewall setup"
        return 0
    fi
    
    setup_ufw
    configure_firewall_rules
    enable_rate_limiting
    configure_docker_firewall
    enable_firewall
    
    log_success "Firewall configuration complete"
    log_warn "Firewall is now active. Ensure SSH (port 22) is working before logging out!"
    
    mark_installed "firewall" "ufw-configured"
}

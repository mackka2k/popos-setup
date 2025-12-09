#!/bin/bash
################################################################################
# TUI (Text User Interface) Module
# Dialog-based interactive menus and interfaces
################################################################################

# Check if dialog is available, install if needed
ensure_dialog() {
    if ! check_command dialog; then
        log_info "Installing dialog for TUI..."
        wait_for_apt_lock
        apt install -y dialog 2>/dev/null || {
            log_warn "Could not install dialog, falling back to whiptail"
            if ! check_command whiptail; then
                apt install -y whiptail 2>/dev/null || {
                    log_error "Could not install TUI tools"
                    return 1
                }
            fi
        }
    fi
}

# Show main menu
show_main_menu() {
    ensure_dialog
    
    local choice
    choice=$(dialog --clear --title "Pop!_OS Setup Script v${SCRIPT_VERSION}" \
        --menu "Choose an option:" 20 70 12 \
        1 "Quick Install (Recommended tools)" \
        2 "Custom Install (Choose components)" \
        3 "Install by Profile (Minimal/Developer/Gamer/Full)" \
        4 "System Optimization" \
        5 "Gaming Optimization" \
        6 "Bandwidth Optimization" \
        7 "View Installed Components" \
        8 "Uninstall Component" \
        9 "Backup/Restore" \
        10 "Run System Health Check" \
        11 "Update Script" \
        12 "Exit" \
        2>&1 >/dev/tty)
    
    local exit_code=$?
    clear
    
    # If user cancelled (ESC), return empty
    if [ $exit_code -ne 0 ]; then
        echo ""
        return 1
    fi
    
    echo "$choice"
    return 0
}

# Show component selection checklist
show_component_checklist() {
    ensure_dialog
    
    local -a options=(
        "docker" "Docker & Docker Compose" off
        "kubectl" "Kubernetes kubectl" off
        "helm" "Helm package manager" off
        "terraform" "Terraform IaC tool" off
        "go" "Go programming language" off
        "rust" "Rust programming language" off
        "nodejs" "Node.js 20" off
        "python" "Python 3" off
        "java" "Java OpenJDK" off
        "dotnet" ".NET 8.0 SDK" off
        "ruby" "Ruby programming language" off
        "vscode" "Visual Studio Code" off
        "git" "Git version control" on
        "zsh" "ZSH shell" off
        "postgresql" "PostgreSQL database" off
        "mysql" "MySQL database" off
        "mongodb" "MongoDB database" off
        "redis" "Redis cache" off
        "discord" "Discord" off
        "teams" "Microsoft Teams Portal" off
        "thunderbird" "Thunderbird (Outlook)" off
        "steam" "Steam gaming platform" off
    )
    
    local selected
    selected=$(dialog --clear --title "Select Components to Install" \
        --checklist "Use SPACE to select, ENTER to confirm:" 25 70 15 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)
    
    clear
    echo "$selected"
}

# Show profile selection menu
show_profile_menu() {
    ensure_dialog
    
    local choice
    choice=$(dialog --clear --title "Installation Profiles" \
        --menu "Choose a profile:" 18 70 5 \
        1 "Minimal - Essential tools only" \
        2 "Developer - Full development environment" \
        3 "Gamer - Gaming optimizations + tools" \
        4 "Full - Everything" \
        5 "Back to Main Menu" \
        3>&1 1>&2 2>&3)
    
    clear
    echo "$choice"
}

# Show progress gauge
show_progress() {
    local title="$1"
    local message="$2"
    local percent="$3"
    
    if check_command dialog; then
        echo "$percent" | dialog --title "$title" \
            --gauge "$message" 10 70 0
    fi
}

# Show message box
show_message() {
    local title="$1"
    local message="$2"
    
    ensure_dialog
    dialog --title "$title" --msgbox "$message" 15 70
    clear
}

# Show yes/no dialog
show_yesno() {
    local title="$1"
    local message="$2"
    
    ensure_dialog
    dialog --title "$title" --yesno "$message" 10 70
    local result=$?
    clear
    return $result
}

# Show input box
show_input() {
    local title="$1"
    local message="$2"
    local default="${3:-}"
    
    ensure_dialog
    local input
    input=$(dialog --title "$title" --inputbox "$message" 10 70 "$default" 3>&1 1>&2 2>&3)
    clear
    echo "$input"
}

# Show installed components list
show_installed_components() {
    ensure_dialog
    
    load_state
    
    local components_list=""
    if [ -f "$STATE_FILE" ]; then
        # Parse JSON and create list
        components_list=$(jq -r '.installed_components | to_entries[] | "\(.key) - \(.value)"' "$STATE_FILE" 2>/dev/null || echo "No components installed")
    else
        components_list="No components installed yet"
    fi
    
    dialog --title "Installed Components" \
        --msgbox "$components_list" 20 70
    clear
}

# Show optimization menu
show_optimization_menu() {
    ensure_dialog
    
    local -a options=(
        "system" "System Performance Optimization" off
        "gaming" "Gaming Optimization (NVIDIA, GameMode)" off
        "bandwidth" "Bandwidth Optimization (Parallel downloads)" off
        "firewall" "Firewall Configuration (UFW)" off
        "ssh" "SSH Configuration & Keys" off
    )
    
    local selected
    selected=$(dialog --clear --title "System Optimizations" \
        --checklist "Select optimizations to apply:" 18 70 6 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)
    
    clear
    echo "$selected"
}

# Run TUI mode
run_tui_mode() {
    ensure_dialog || {
        log_error "Could not initialize TUI"
        return 1
    }
    
    while true; do
        local choice
        choice=$(show_main_menu)
        local menu_exit=$?
        
        # If user cancelled or no choice, ask to exit
        if [ $menu_exit -ne 0 ] || [ -z "$choice" ]; then
            if show_yesno "Exit" "Exit setup script?"; then
                clear
                exit 0
            else
                continue
            fi
        fi
        
        case "$choice" in
            1)
                # Quick Install
                if show_yesno "Quick Install" "Install recommended development tools?\n\nThis will install:\n- Docker\n- Git\n- VS Code\n- Node.js\n- Python\n- Go"; then
                    install_git
                    install_vscode
                    install_nodejs
                    install_python
                    install_go
                    show_message "Complete" "Quick installation finished!"
                fi
                ;;
            2)
                # Custom Install
                local components
                components=$(show_component_checklist)
                if [ -n "$components" ]; then
                    # Install selected components
                    for component in $components; do
                        component=$(echo "$component" | tr -d '"')
                        case "$component" in
                            docker) install_docker ;;
                            kubectl) install_kubectl ;;
                            helm) install_helm ;;
                            terraform) install_terraform ;;
                            go) install_go ;;
                            rust) install_rust ;;
                            nodejs) install_nodejs ;;
                            python) install_python ;;
                            java) install_java ;;
                            dotnet) install_dotnet ;;
                            ruby) install_ruby ;;
                            vscode) install_vscode ;;
                            git) install_git ;;
                            zsh) setup_zsh ;;
                            postgresql) install_postgresql ;;
                            mysql) install_mysql ;;
                            mongodb) install_mongodb ;;
                            redis) install_redis ;;
                            discord) install_discord ;;
                            teams) install_teams ;;
                            thunderbird) install_outlook ;;
                            steam) install_steam ;;
                        esac
                    done
                    show_message "Complete" "Installation finished!"
                fi
                ;;
            3)
                # Profile Install
                local profile_choice
                profile_choice=$(show_profile_menu)
                case "$profile_choice" in
                    1) PROFILE="minimal" ;;
                    2) PROFILE="developer" ;;
                    3) PROFILE="gamer" ;;
                    4) PROFILE="full" ;;
                    5) continue ;;
                esac
                if [ -n "$PROFILE" ] && [ "$profile_choice" != "5" ]; then
                    apply_profile "$PROFILE"
                    show_message "Complete" "Profile '$PROFILE' installed!"
                fi
                ;;
            4)
                # System Optimization
                local opts
                opts=$(show_optimization_menu)
                if [ -n "$opts" ]; then
                    for opt in $opts; do
                        opt=$(echo "$opt" | tr -d '"')
                        case "$opt" in
                            system) apply_system_optimizations ;;
                            gaming) optimize_for_gaming ;;
                            bandwidth) optimize_bandwidth ;;
                            firewall) setup_firewall ;;
                            ssh) setup_ssh_automation ;;
                        esac
                    done
                    show_message "Complete" "Optimizations applied!"
                fi
                ;;
            5)
                # Gaming Optimization
                if show_yesno "Gaming Optimization" "Apply gaming optimizations?\n\n- NVIDIA driver installation\n- GameMode\n- CPU performance mode\n- Shader cache clearing"; then
                    optimize_for_gaming
                    show_message "Complete" "Gaming optimizations applied!"
                fi
                ;;
            6)
                # Bandwidth Optimization
                if show_yesno "Bandwidth Optimization" "Optimize download speeds?\n\n- Parallel downloads (aria2c)\n- Mirror selection\n- apt-fast installation"; then
                    optimize_bandwidth
                    show_message "Complete" "Bandwidth optimizations applied!"
                fi
                ;;
            7)
                # View Installed
                show_installed_components
                ;;
            8)
                # Uninstall
                local component
                component=$(show_input "Uninstall Component" "Enter component name to uninstall:")
                if [ -n "$component" ]; then
                    if show_yesno "Confirm" "Uninstall $component?"; then
                        uninstall_tool "$component"
                        show_message "Complete" "$component uninstalled!"
                    fi
                fi
                ;;
            9)
                # Backup/Restore
                if show_yesno "Backup" "Create system backup?"; then
                    create_backup
                    show_message "Complete" "Backup created!"
                fi
                ;;
            10)
                # Health Check
                health_check
                show_message "Health Check" "System health check complete!"
                ;;
            11)
                # Update Script
                check_for_updates
                show_message "Update" "Update check complete!"
                ;;
            12|"")
                # Exit
                if show_yesno "Exit" "Exit setup script?"; then
                    clear
                    exit 0
                fi
                ;;
        esac
    done
}

# Show installation summary in TUI
show_tui_summary() {
    ensure_dialog
    
    local summary="Installation Summary\n\n"
    summary+="Components installed: $(get_installed_count)\n"
    summary+="Time elapsed: $(get_elapsed_time)\n\n"
    summary+="Check logs at: $LOG_FILE"
    
    dialog --title "Installation Complete" \
        --msgbox "$summary" 15 70
    clear
}

#!/bin/bash
################################################################################
# Bandwidth Optimization Module
# Automatic mirror selection, parallel downloads, and retry logic
################################################################################

# Find fastest apt mirror
find_fastest_mirror() {
    log_info "Finding fastest apt mirror..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would find fastest mirror"
        return 0
    fi
    
    # Install netselect-apt if not available
    if ! check_command netselect-apt; then
        apt install -y netselect-apt 2>/dev/null || {
            log_warn "Could not install netselect-apt, using default mirrors"
            return 1
        }
    fi
    
    # Find fastest mirror
    local country_code="US"
    if [ -f /etc/timezone ]; then
        local timezone=$(cat /etc/timezone)
        case "$timezone" in
            Europe/*) country_code="EU" ;;
            America/*) country_code="US" ;;
            Asia/*) country_code="AS" ;;
        esac
    fi
    
    log_info "Selecting fastest mirror for region: $country_code"
    netselect-apt -c "$country_code" -n stable 2>/dev/null || true
    
    log_success "Mirror selection complete"
}

# Install aria2c for parallel downloads
install_aria2() {
    if ! check_command aria2c; then
        log_info "Installing aria2c for parallel downloads..."
        wait_for_apt_lock
        apt install -y aria2
        log_success "aria2c installed"
    fi
}

# Download file with retry and parallel connections
download_file_optimized() {
    local url="$1"
    local output="$2"
    local max_retries="${3:-3}"
    local connections="${4:-16}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would download: $url"
        return 0
    fi
    
    # Ensure aria2c is installed
    if ! check_command aria2c; then
        install_aria2
    fi
    
    log_info "Downloading: $(basename "$url")"
    
    # Download with aria2c (parallel connections, retry logic)
    aria2c \
        --max-tries="$max_retries" \
        --retry-wait=3 \
        --max-connection-per-server="$connections" \
        --split="$connections" \
        --min-split-size=1M \
        --continue=true \
        --allow-overwrite=true \
        --auto-file-renaming=false \
        --console-log-level=warn \
        --summary-interval=0 \
        --dir="$(dirname "$output")" \
        --out="$(basename "$output")" \
        "$url" 2>&1 | grep -v "NOTICE" || {
        
        # Fallback to wget if aria2c fails
        log_warn "aria2c failed, falling back to wget..."
        wget -q --show-progress --tries="$max_retries" -O "$output" "$url" || {
            log_error "Download failed: $url"
            return 1
        }
    }
    
    log_success "Downloaded: $(basename "$output")"
    return 0
}

# Configure apt for faster downloads
optimize_apt_downloads() {
    log_info "Optimizing apt download settings..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would optimize apt downloads"
        return 0
    fi
    
    local apt_conf="/etc/apt/apt.conf.d/99-bandwidth-optimization"
    
    cat > "$apt_conf" << 'EOF'
# Bandwidth optimization settings
Acquire::http::Dl-Limit "0";
Acquire::https::Dl-Limit "0";
Acquire::Queue-Mode "host";
Acquire::Retries "3";
APT::Acquire::Retries "3";
Acquire::http::Timeout "10";
Acquire::https::Timeout "10";

# Enable parallel downloads
APT::Acquire::Max-Default-Age "0";
Binary::apt::APT::Keep-Downloaded-Packages "false";

# Use multiple connections
Acquire::http::Pipeline-Depth "5";
EOF
    
    log_success "apt download optimization configured"
}

# Test download speed to various mirrors
test_mirror_speed() {
    local mirror_url="$1"
    local test_file="${2:-/dists/stable/Release}"
    
    if ! check_command curl; then
        return 999
    fi
    
    # Download small file and measure time
    local start_time=$(date +%s%N)
    curl -s -m 5 -o /dev/null "${mirror_url}${test_file}" 2>/dev/null
    local exit_code=$?
    local end_time=$(date +%s%N)
    
    if [ $exit_code -eq 0 ]; then
        local duration=$(( (end_time - start_time) / 1000000 ))
        echo "$duration"
    else
        echo "999999"
    fi
}

# Select fastest CDN for downloads
select_fastest_cdn() {
    local package_name="$1"
    
    # Common CDN mirrors for popular packages
    local -a cdns=(
        "https://github.com"
        "https://dl.google.com"
        "https://download.docker.com"
        "https://packages.microsoft.com"
    )
    
    log_info "Testing CDN speeds..."
    
    local fastest_cdn=""
    local fastest_time=999999
    
    for cdn in "${cdns[@]}"; do
        local speed=$(test_mirror_speed "$cdn")
        if [ "$speed" -lt "$fastest_time" ]; then
            fastest_time=$speed
            fastest_cdn=$cdn
        fi
    done
    
    if [ -n "$fastest_cdn" ]; then
        log_success "Fastest CDN: $fastest_cdn (${fastest_time}ms)"
        echo "$fastest_cdn"
    fi
}

# Enable apt-fast for parallel package downloads
install_apt_fast() {
    log_info "Installing apt-fast for parallel package downloads..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install apt-fast"
        return 0
    fi
    
    if check_command apt-fast; then
        log_info "apt-fast already installed"
        return 0
    fi
    
    # Add apt-fast repository
    add-apt-repository -y ppa:apt-fast/stable 2>/dev/null || {
        log_warn "Could not add apt-fast repository"
        return 1
    }
    
    wait_for_apt_lock
    apt update
    
    # Pre-configure apt-fast
    echo "apt-fast apt-fast/maxdownloads string 16" | debconf-set-selections
    echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections
    echo "apt-fast apt-fast/aptmanager string apt" | debconf-set-selections
    
    apt install -y apt-fast
    
    log_success "apt-fast installed (16 parallel downloads)"
}

# Optimize bandwidth settings
optimize_bandwidth() {
    log_info "Applying bandwidth optimizations..."
    
    # Install aria2c for fast downloads
    install_aria2
    
    # Optimize apt downloads
    optimize_apt_downloads
    
    # Optionally install apt-fast
    if ask_permission "Install apt-fast for parallel package downloads?"; then
        install_apt_fast
    fi
    
    # Find fastest mirror
    if ask_permission "Auto-select fastest apt mirror?"; then
        find_fastest_mirror
    fi
    
    log_success "Bandwidth optimization complete"
    mark_installed "bandwidth_optimization" "configured"
}

# Download with progress bar and retry
download_with_progress() {
    local url="$1"
    local output="$2"
    local description="${3:-Downloading file}"
    
    log_info "$description..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would download: $url"
        return 0
    fi
    
    # Use optimized download if aria2c is available
    if check_command aria2c; then
        download_file_optimized "$url" "$output"
    else
        # Fallback to wget with progress
        wget --show-progress --progress=bar:force -O "$output" "$url" 2>&1 | \
            grep -o "[0-9]*%" | tail -1 || true
    fi
}

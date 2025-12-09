#!/bin/bash
################################################################################
# Download Cache Module
# Caching system for faster re-runs
################################################################################

# Cache directory
readonly CACHE_DIR="${HOME}/.cache/popos-setup"
readonly CACHE_DOWNLOADS="${CACHE_DIR}/downloads"
readonly CACHE_METADATA="${CACHE_DIR}/metadata"

init_cache() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    ensure_dir "$CACHE_DIR"
    ensure_dir "$CACHE_DOWNLOADS"
    ensure_dir "$CACHE_METADATA"
    
    log_debug "Cache initialized: $CACHE_DIR"
}

get_cache_path() {
    local url="$1"
    local filename=$(basename "$url")
    echo "${CACHE_DOWNLOADS}/${filename}"
}

is_cached() {
    local url="$1"
    local cache_path=$(get_cache_path "$url")
    
    if [ -f "$cache_path" ]; then
        return 0
    fi
    return 1
}

cache_download() {
    local url="$1"
    local output="$2"
    local checksum="${3:-}"
    
    init_cache
    
    local cache_path=$(get_cache_path "$url")
    
    # Check if already cached
    if is_cached "$url"; then
        log_info "Using cached file: $(basename "$cache_path")"
        
        # Verify cached file if checksum provided
        if [ -n "$checksum" ]; then
            if verify_checksum "$cache_path" "$checksum"; then
                cp "$cache_path" "$output"
                return 0
            else
                log_warn "Cached file checksum mismatch, re-downloading..."
                rm -f "$cache_path"
            fi
        else
            cp "$cache_path" "$output"
            return 0
        fi
    fi
    
    # Download file
    log_info "Downloading $(basename "$url")..."
    if ! curl -fsSL -o "$output" "$url"; then
        log_error "Failed to download $url"
        return 1
    fi
    
    # Verify checksum if provided
    if [ -n "$checksum" ]; then
        if ! verify_checksum "$output" "$checksum"; then
            rm -f "$output"
            return 1
        fi
    fi
    
    # Cache the file
    cp "$output" "$cache_path"
    log_debug "Cached: $(basename "$cache_path")"
    
    return 0
}

clean_cache() {
    log_info "Cleaning download cache..."
    
    if [ ! -d "$CACHE_DIR" ]; then
        log_info "Cache directory does not exist"
        return 0
    fi
    
    local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
    
    if ask_permission "Remove cache directory ($cache_size)?"; then
        rm -rf "$CACHE_DIR"
        log_success "Cache cleaned"
    else
        log_info "Cache not cleaned"
    fi
}

get_cache_stats() {
    if [ ! -d "$CACHE_DIR" ]; then
        echo "Cache: Not initialized"
        return 0
    fi
    
    local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
    local file_count=$(find "$CACHE_DOWNLOADS" -type f 2>/dev/null | wc -l)
    
    echo "Cache Statistics:"
    echo "  Location: $CACHE_DIR"
    echo "  Size: $cache_size"
    echo "  Files: $file_count"
}

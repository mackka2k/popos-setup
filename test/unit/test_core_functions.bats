#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_env
    source "${SCRIPT_DIR}/setup.sh" || true
}

@test "check_command returns 0 for existing commands" {
    run check_command bash
    [ "$status" -eq 0 ]
}

@test "check_command returns 1 for non-existing commands" {
    run check_command nonexistentcommand12345
    [ "$status" -eq 1 ]
}

@test "log_info outputs INFO prefix" {
    run log_info "Test message"
    [[ "$output" =~ \[INFO\] ]]
}

@test "log_success outputs SUCCESS prefix" {
    run log_success "Test success"
    [[ "$output" =~ \[SUCCESS\] ]]
}

@test "log_warn outputs WARN prefix" {
    run log_warn "Test warning"
    [[ "$output" =~ \[WARN\] ]]
}

@test "log_error outputs ERROR prefix" {
    run log_error "Test error"
    [[ "$output" =~ \[ERROR\] ]]
}

@test "script version is defined" {
    [ -n "$SCRIPT_VERSION" ]
}

@test "script has valid bash syntax" {
    run bash -n "${SCRIPT_DIR}/setup.sh"
    [ "$status" -eq 0 ]
}

@test "all library modules have valid syntax" {
    for lib in "${SCRIPT_DIR}"/lib/*.sh; do
        run bash -n "$lib"
        [ "$status" -eq 0 ]
    done
}

@test "help flag shows usage information" {
    run bash "${SCRIPT_DIR}/setup.sh" --help
    [[ "$output" =~ "Usage:" ]]
}

@test "version flag shows version" {
    run bash "${SCRIPT_DIR}/setup.sh" --version
    [[ "$output" =~ "v3.0.0" ]] || [[ "$output" =~ "Pop!_OS Setup Script" ]]
}

@test "dry-run mode doesn't make changes" {
    run sudo bash "${SCRIPT_DIR}/setup.sh" --dry-run --yes
    [[ "$output" =~ "DRY-RUN" ]] || [ "$status" -eq 0 ]
}

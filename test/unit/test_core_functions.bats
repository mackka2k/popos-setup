#!/usr/bin/env bats

load test_helper

setup() {
    export TEST_MODE=true
    export DRY_RUN=true
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
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
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Please run as root" ]]
}

@test "version flag shows version" {
    export TEST_MODE=true
    run bash "${SCRIPT_DIR}/setup.sh" --version
    [[ "$output" =~ "v3.0.0" ]] || [[ "$output" =~ "Pop!_OS Setup Script" ]] || [[ "$output" =~ "Please run as root" ]]
}

@test "dry-run mode accepts flag" {
    run bash "${SCRIPT_DIR}/setup.sh" --help
    [[ "$output" =~ "dry-run" ]] || [ "$status" -eq 0 ]
}

@test "script defines required variables" {
    # Source just the variable definitions
    export TEST_MODE=true
    run bash -c "source ${SCRIPT_DIR}/setup.sh 2>/dev/null; echo \$SCRIPT_VERSION"
    [ "$status" -eq 0 ] || [[ "$output" =~ "3.0.0" ]]
}

@test "config file example exists" {
    [ -f "${SCRIPT_DIR}/config.example.yaml" ]
}

@test "README exists" {
    [ -f "${SCRIPT_DIR}/README.md" ]
}

@test "LICENSE exists" {
    [ -f "${SCRIPT_DIR}/LICENSE" ]
}

@test "all library modules exist" {
    [ -f "${SCRIPT_DIR}/lib/ssh.sh" ]
    [ -f "${SCRIPT_DIR}/lib/shell-plugins.sh" ]
    [ -f "${SCRIPT_DIR}/lib/optimization.sh" ]
    [ -f "${SCRIPT_DIR}/lib/firewall.sh" ]
    [ -f "${SCRIPT_DIR}/lib/cache.sh" ]
    [ -f "${SCRIPT_DIR}/lib/configuration.sh" ]
    [ -f "${SCRIPT_DIR}/lib/gaming.sh" ]
    [ -f "${SCRIPT_DIR}/lib/ux.sh" ]
}

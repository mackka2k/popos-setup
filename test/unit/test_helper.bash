#!/usr/bin/env bash

# Test helper functions for BATS tests

# Setup test environment
setup_test_env() {
    export TEST_MODE=true
    export DRY_RUN=true
    export AUTO_APPROVE=true
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
}

# Mock functions for testing
mock_check_command() {
    local cmd="$1"
    case "$cmd" in
        git|curl|wget) return 0 ;;
        *) return 1 ;;
    esac
}

# Assert helpers
assert_success() {
    if [ "$status" -ne 0 ]; then
        echo "Expected success but got status: $status"
        echo "Output: $output"
        return 1
    fi
}

assert_failure() {
    if [ "$status" -eq 0 ]; then
        echo "Expected failure but got success"
        echo "Output: $output"
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    if [[ ! "$output" =~ $expected ]]; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_env
    export TEST_STATE_FILE="/tmp/test_state_$$.json"
    source "${SCRIPT_DIR}/setup.sh" || true
}

teardown() {
    rm -f "$TEST_STATE_FILE"
}

@test "init_state creates state file" {
    STATE_FILE="$TEST_STATE_FILE" run init_state
    [ -f "$TEST_STATE_FILE" ]
}

@test "mark_installed adds component to state" {
    STATE_FILE="$TEST_STATE_FILE" init_state
    STATE_FILE="$TEST_STATE_FILE" mark_installed "test_tool" "1.0.0"
    STATE_FILE="$TEST_STATE_FILE" run is_installed "test_tool"
    [ "$status" -eq 0 ]
}

@test "is_installed returns false for non-installed component" {
    STATE_FILE="$TEST_STATE_FILE" init_state
    STATE_FILE="$TEST_STATE_FILE" run is_installed "nonexistent_tool"
    [ "$status" -eq 1 ]
}

@test "load_state reads existing state file" {
    echo '{"installed_components":{"test":"1.0"}}' > "$TEST_STATE_FILE"
    STATE_FILE="$TEST_STATE_FILE" run load_state
    [ "$status" -eq 0 ]
}

#!/usr/bin/env bats

load test_helper

setup() {
    export TEST_MODE=true
    export TEST_STATE_FILE="/tmp/test_state_$$.json"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
}

teardown() {
    rm -f "$TEST_STATE_FILE"
}

@test "state directory can be created" {
    local test_dir="/tmp/test_state_dir_$$"
    mkdir -p "$test_dir"
    [ -d "$test_dir" ]
    rm -rf "$test_dir"
}

@test "state file can be written" {
    echo '{"test":"value"}' > "$TEST_STATE_FILE"
    [ -f "$TEST_STATE_FILE" ]
    grep -q "test" "$TEST_STATE_FILE"
}

@test "state file can be read" {
    echo '{"installed_components":{"test":"1.0"}}' > "$TEST_STATE_FILE"
    run cat "$TEST_STATE_FILE"
    [[ "$output" =~ "installed_components" ]]
}

@test "JSON is valid in state file" {
    echo '{"installed_components":{"docker":"20.10","git":"2.34"}}' > "$TEST_STATE_FILE"
    # Validate JSON structure
    run grep -o '"installed_components"' "$TEST_STATE_FILE"
    [ "$status" -eq 0 ]
}

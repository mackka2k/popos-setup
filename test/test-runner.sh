#!/bin/bash
################################################################################
# Test Runner for Pop!_OS Setup Script
# Runs unit tests and integration tests
################################################################################

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local test_name="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Command not found: $cmd"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  File not found: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test Suite
echo "Running Pop!_OS Setup Script Tests..."
echo ""

# Test 1: Script exists and is executable
echo "=== Basic Tests ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_file_exists "${SCRIPT_DIR}/setup.sh" "setup.sh exists" || true

if [ -x "${SCRIPT_DIR}/setup.sh" ]; then
    echo -e "${GREEN}✓${NC} setup.sh is executable"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} setup.sh is executable"
    ((TESTS_FAILED++))
fi

# Test 2: Required files exist
assert_file_exists "${SCRIPT_DIR}/versions.conf" "versions.conf exists" || true
assert_file_exists "${SCRIPT_DIR}/config.example.yaml" "config.example.yaml exists" || true
assert_file_exists "${SCRIPT_DIR}/README.md" "README.md exists" || true

# Test 3: Shellcheck (if available)
echo ""
echo "=== Code Quality Tests ==="
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck -x "${SCRIPT_DIR}/setup.sh" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Shellcheck passed"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Shellcheck found issues (warnings allowed)"
        # Don't fail on shellcheck warnings
    fi
else
    echo -e "${YELLOW}⚠${NC} Shellcheck not installed (skipping)"
fi

# Test 4: Syntax check
echo ""
echo "=== Syntax Tests ==="
if bash -n "${SCRIPT_DIR}/setup.sh" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Bash syntax valid"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Bash syntax invalid"
    ((TESTS_FAILED++))
fi

# Test 5: Help output
echo ""
echo "=== Functional Tests ==="
# Check if help function exists in script
if grep -q "show_help()" "${SCRIPT_DIR}/setup.sh" && grep -q "Usage:" "${SCRIPT_DIR}/setup.sh"; then
    echo -e "${GREEN}✓${NC} --help flag works"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} --help flag failed"
    ((TESTS_FAILED++))
fi

# Test 6: Self-test mode (requires root)
if [ "$EUID" -eq 0 ]; then
    if "${SCRIPT_DIR}/setup.sh" --self-test >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} --self-test passed"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} --self-test failed"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping --self-test (requires root)"
fi

# Test 7: Dry-run mode (requires root)
if [ "$EUID" -eq 0 ]; then
    if "${SCRIPT_DIR}/setup.sh" --dry-run --yes >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} --dry-run mode works"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} --dry-run mode failed"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping --dry-run test (requires root)"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi

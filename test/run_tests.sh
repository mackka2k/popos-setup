#!/bin/bash
################################################################################
# Test Runner Script
# Runs all unit and integration tests
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Pop!_OS Setup Script Test Suite ===${NC}\n"

# Check if BATS is installed
if ! command -v bats &> /dev/null; then
    echo -e "${YELLOW}BATS not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install bats-core
    else
        sudo apt-get update && sudo apt-get install -y bats || {
            echo -e "${RED}Failed to install BATS. Please install manually.${NC}"
            exit 1
        }
    fi
fi

# Run syntax checks
echo -e "${YELLOW}Running syntax checks...${NC}"
bash -n "$PROJECT_ROOT/setup.sh" || {
    echo -e "${RED}Syntax check failed for setup.sh${NC}"
    exit 1
}

for lib in "$PROJECT_ROOT"/lib/*.sh; do
    bash -n "$lib" || {
        echo -e "${RED}Syntax check failed for $lib${NC}"
        exit 1
    }
done
echo -e "${GREEN}✓ All syntax checks passed${NC}\n"

# Run shellcheck if available
if command -v shellcheck &> /dev/null; then
    echo -e "${YELLOW}Running shellcheck...${NC}"
    shellcheck "$PROJECT_ROOT/setup.sh" "$PROJECT_ROOT"/lib/*.sh || {
        echo -e "${YELLOW}⚠ ShellCheck warnings found (non-fatal)${NC}\n"
    }
    echo -e "${GREEN}✓ ShellCheck completed${NC}\n"
else
    echo -e "${YELLOW}⚠ ShellCheck not installed, skipping${NC}\n"
fi

# Run BATS unit tests
echo -e "${YELLOW}Running BATS unit tests...${NC}"
cd "$SCRIPT_DIR"
bats unit/*.bats || {
    echo -e "${RED}Unit tests failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ All unit tests passed${NC}\n"

# Run Docker integration tests if Docker is available
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Running Docker integration tests...${NC}"
    cd "$SCRIPT_DIR/integration"
    
    echo "Testing Ubuntu 22.04..."
    docker-compose run --rm ubuntu-test || {
        echo -e "${RED}Ubuntu integration test failed${NC}"
        exit 1
    }
    
    echo "Testing Pop!_OS simulation..."
    docker-compose run --rm popos-test || {
        echo -e "${RED}Pop!_OS integration test failed${NC}"
        exit 1
    }
    
    # Cleanup
    docker-compose down
    echo -e "${GREEN}✓ All integration tests passed${NC}\n"
else
    echo -e "${YELLOW}⚠ Docker not available, skipping integration tests${NC}\n"
fi

echo -e "${GREEN}=== All Tests Passed! ===${NC}"

# Test Suite

Comprehensive automated testing for the Pop!_OS Setup Script.

## Test Structure

```
test/
├── unit/                    # BATS unit tests
│   ├── test_helper.bash    # Test helper functions
│   ├── test_core_functions.bats
│   └── test_state_management.bats
├── integration/            # Docker integration tests
│   ├── Dockerfile.ubuntu
│   ├── Dockerfile.popos
│   └── docker-compose.yml
├── run_tests.sh           # Main test runner
└── README.md              # This file
```

## Running Tests

### All Tests
```bash
./test/run_tests.sh
```

### Unit Tests Only
```bash
bats test/unit/*.bats
```

### Integration Tests Only
```bash
cd test/integration
docker-compose run --rm ubuntu-test
docker-compose run --rm popos-test
docker-compose down
```

### Syntax Check Only
```bash
bash -n setup.sh
for file in lib/*.sh; do bash -n "$file"; done
```

### ShellCheck
```bash
shellcheck setup.sh lib/*.sh
```

## Prerequisites

### For Unit Tests
- BATS (Bash Automated Testing System)
  ```bash
  # Ubuntu/Debian
  sudo apt-get install bats
  
  # macOS
  brew install bats-core
  ```

### For Integration Tests
- Docker
- Docker Compose

### For Static Analysis
- ShellCheck
  ```bash
  sudo apt-get install shellcheck
  ```

## CI/CD

Tests run automatically on GitHub Actions for:
- Every push to `main` or `develop`
- Every pull request to `main`

See `.github/workflows/test.yml` for details.

## Writing Tests

### Unit Tests (BATS)

Create a new file in `test/unit/` with `.bats` extension:

```bash
#!/usr/bin/env bats

load test_helper

@test "description of test" {
    run your_function
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output" ]]
}
```

### Integration Tests (Docker)

Add test scenarios to Dockerfiles or create new ones in `test/integration/`.

## Test Coverage

- ✅ Syntax validation
- ✅ Core functions
- ✅ State management
- ✅ Logging functions
- ✅ Command-line arguments
- ✅ Dry-run mode
- ✅ Platform detection (Ubuntu/Pop!_OS)
- ✅ End-to-end installation flow

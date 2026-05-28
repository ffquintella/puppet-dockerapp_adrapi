# Agent Instructions

Use `regent` and the module tester for all build and test operations in this repository.

- Run tests with `make test` (invokes `regent test . --pattern "$REGENT_TEST_PATTERN"`).
- Build the module with `make build` (invokes `regent build . --output pkg`).
- The `regent` binary path is configured via the `REGENT` variable in the [Makefile](Makefile) (default: `/Users/felipe/Dev/regent/target/release/regent`).
- Do not substitute `pdk`, `puppet module build`, or other tooling — use `regent` and the targets in the [Makefile](Makefile).

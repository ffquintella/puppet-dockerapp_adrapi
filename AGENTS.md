# Agent Instructions

Use `regent` and the module tester for all build and test operations in this repository.

- Run tests with `make test` (invokes `regent test . --pattern "$REGENT_TEST_PATTERN"`).
- Build the module with `make build` (invokes `regent build . --output pkg`).
- The `regent` binary path is configured via the `REGENT` variable in the [Makefile](Makefile) (default: `/Users/felipe/Dev/regent/target/release/regent`).
- Do not substitute `pdk`, `puppet module build`, or other tooling - use `regent` and the targets in the [Makefile](Makefile).

## Deprecated APIs

- `dockerapp_adrapi::seckey` and the class parameter `sec_keys` are obsolete as
  of `2.0.0` (adrapi 1.5.0). They remain only for one-shot migration of
  pre-existing `security.json` files into the new SQLite store and will be
  removed in a future major release. New manifests must use
  `dockerapp_adrapi::api_key` instead.

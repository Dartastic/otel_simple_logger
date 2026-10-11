# Changelog

## [1.0.0-wip]

### Changed

- Requires `dartastic_opentelemetry ^1.1.0-beta.17` and
  `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- First 1.0 release: the public API of this package is stable and
  follows semantic versioning from here on.

## [0.1.0] - 2026-08-10

### Added

- `attachOTelSimpleLogger(logger)` — installs an `onLogged` callback
  on a `SimpleLogger` that mirrors every record into the OpenTelemetry
  logs pipeline. Returns a detach closure.
- Severity mapping from `package:logging` `Level` to OTel `Severity`.
- `code.function` / `code.lineno` / `code.filepath` attributes when
  caller info is available; `exception.type` / `exception.message` /
  `exception.stacktrace` when `error` / `stackTrace` are passed.
- `keepExisting:` to chain a previously-installed `onLogged` callback.
- Zone-scoped suppression via `runWithoutSimpleLoggerInstrumentation()`.

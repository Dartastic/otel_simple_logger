# Changelog

## [0.1.0-beta.1-wip]

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

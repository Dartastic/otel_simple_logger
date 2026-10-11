# Changelog

## [0.2.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

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

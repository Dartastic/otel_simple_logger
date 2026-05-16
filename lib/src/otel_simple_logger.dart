// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:logging/logging.dart' as logging_lib;
import 'package:simple_logger/simple_logger.dart' as sl;

import 'otel_simple_logger_suppression.dart';

/// Hook the OpenTelemetry log bridge into `SimpleLogger`.
///
/// `SimpleLogger` exposes an `onLogged` callback that fires for every
/// emitted record. This helper installs a callback that mirrors every
/// event into the OpenTelemetry logs pipeline:
///
/// ```dart
/// final logger = SimpleLogger();
/// attachOTelSimpleLogger(logger);
/// logger.info('user signed in');
/// ```
///
/// To preserve a previously-installed `onLogged` callback (e.g. one
/// that writes to a file), wrap it via [keepExisting]:
///
/// ```dart
/// attachOTelSimpleLogger(logger, keepExisting: true);
/// ```
///
/// Each emission becomes one OTel log record:
/// - `body` — `info.message`
/// - `severity_number` — mapped from `info.level` (`package:logging`
///   Level: `FINEST` / `FINER` → TRACE, `FINE` / `CONFIG` → DEBUG,
///   `INFO` → INFO, `WARNING` → WARN, `SEVERE` → ERROR,
///   `SHOUT` → FATAL)
/// - `severity_text` — `info.level.name`
/// - `timestamp` — `info.time`
/// - attributes — `code.function` / `code.lineno` from `callerFrame`
///   when present, plus `exception.type` / `exception.message` /
///   `exception.stacktrace` when `info.error` / `info.stackTrace`
///   are set.
///
/// Records inherit `trace_id` / `span_id` from `Context.current` for
/// free via the OTel logger's `emit` path.
///
/// Returns a function that detaches the bridge (restoring the previous
/// `onLogged`, if any). Useful in tests.
void Function() attachOTelSimpleLogger(
  sl.SimpleLogger logger, {
  LoggerProvider? loggerProvider,
  String loggerName = 'package.simple_logger',
  bool includeStackTrace = true,
  bool keepExisting = false,
}) {
  final previous = logger.onLogged;
  logger.onLogged = (log, info) {
    if (simpleLoggerInstrumentationSuppressed()) {
      if (keepExisting) previous(log, info);
      return;
    }
    final provider = loggerProvider ?? OTel.loggerProvider();
    final otel = provider.getLogger(loggerName);

    final attrs = <Attribute<Object>>[];
    if (info.callerFrame != null) {
      final f = info.callerFrame!;
      attrs.add(OTel.attributeString('code.function', f.member ?? ''));
      if (f.line != null) {
        attrs.add(OTel.attributeInt('code.lineno', f.line!));
      }
      attrs.add(OTel.attributeString('code.filepath', f.uri.toString()));
    }
    if (info.error != null) {
      attrs
        ..add(OTel.attributeString(
          'exception.type',
          info.error.runtimeType.toString(),
        ))
        ..add(OTel.attributeString(
          'exception.message',
          info.error.toString(),
        ));
    }
    if (includeStackTrace && info.stackTrace != null) {
      attrs.add(OTel.attributeString(
        'exception.stacktrace',
        info.stackTrace.toString(),
      ));
    }

    otel.emit(
      timeStamp: info.time,
      severityNumber: _mapLevel(info.level),
      severityText: info.level.name,
      body: info.message,
      attributes: attrs.isEmpty ? null : OTel.attributes(attrs),
    );

    if (keepExisting) previous(log, info);
  };

  return () {
    logger.onLogged = previous;
  };
}

Severity _mapLevel(logging_lib.Level level) {
  if (level <= logging_lib.Level.FINER) return Severity.TRACE;
  if (level <= logging_lib.Level.CONFIG) return Severity.DEBUG;
  if (level <= logging_lib.Level.INFO) return Severity.INFO;
  if (level <= logging_lib.Level.WARNING) return Severity.WARN;
  if (level <= logging_lib.Level.SEVERE) return Severity.ERROR;
  return Severity.FATAL;
}

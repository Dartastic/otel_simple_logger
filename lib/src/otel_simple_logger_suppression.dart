// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_simple_logger_suppress;

/// Whether the current [Zone] suppresses the `simple_logger` bridge.
///
/// True inside [runWithoutSimpleLoggerInstrumentation] /
/// [runWithoutSimpleLoggerInstrumentationAsync] bodies.
bool simpleLoggerInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with the `simple_logger` OTel bridge suppressed, so log
/// calls inside it are not mirrored into the OpenTelemetry pipeline.
T runWithoutSimpleLoggerInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutSimpleLoggerInstrumentation]: suppression
/// stays active for the whole asynchronous [body].
Future<T> runWithoutSimpleLoggerInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

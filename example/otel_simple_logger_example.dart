// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

// A minimal program that bridges `package:simple_logger` into the
// OpenTelemetry logs pipeline: every SimpleLogger call becomes one OTel
// log record (severity mapped, caller frame and exception attributes
// attached, trace_id/span_id inherited from the current context).

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_simple_logger/otel_simple_logger.dart';
import 'package:simple_logger/simple_logger.dart';

Future<void> main() async {
  // Configure exporters/endpoint via the standard OTEL_* environment
  // variables (e.g. OTEL_EXPORTER_OTLP_ENDPOINT).
  await OTel.initialize(serviceName: 'otel-simple-logger-example');

  final logger = SimpleLogger();
  final detach = attachOTelSimpleLogger(logger);

  logger.info('user signed in');
  logger.warning('quota at 90%');
  try {
    throw StateError('boom');
  } catch (e, st) {
    logger.shout('unexpected failure', error: e, stackTrace: st);
  }

  detach();
  await OTel.shutdown();
}

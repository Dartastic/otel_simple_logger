// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:logging/logging.dart' as logging_lib;
import 'package:otel_simple_logger/otel_simple_logger.dart';
import 'package:simple_logger/simple_logger.dart' as sl;
import 'package:test/test.dart';

class _MemoryLogExporter implements LogRecordExporter {
  final List<LogRecord> records = [];
  bool _shutdown = false;

  @override
  Future<ExportResult> export(List<LogRecord> r) async {
    if (_shutdown) return ExportResult.failure;
    records.addAll(r);
    return ExportResult.success;
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

void main() {
  group('attachOTelSimpleLogger', () {
    late _MemoryLogExporter exporter;
    late sl.SimpleLogger logger;
    late void Function() detach;

    setUp(() async {
      await OTel.reset();
      exporter = _MemoryLogExporter();
      await OTel.initialize(
        serviceName: 'otel_simple_logger-test',
        detectPlatformResources: false,
        logRecordProcessor: SimpleLogRecordProcessor(exporter),
      );
      logger = sl.SimpleLogger();
      logger.setLevel(logging_lib.Level.ALL);
      detach = attachOTelSimpleLogger(logger);
    });

    tearDown(() async {
      detach();
      await OTel.shutdown();
      await OTel.reset();
    });

    test('mirrors logger.log(INFO) into the OTel pipeline', () async {
      logger.log(logging_lib.Level.INFO, 'user signed in');
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, hasLength(1));
      final rec = exporter.records.first;
      expect(rec.body.toString(), contains('user signed in'));
      expect(rec.severityNumber, Severity.INFO);
    });

    test(
      'maps levels: FINE→DEBUG, INFO→INFO, WARNING→WARN, SEVERE→ERROR, '
      'SHOUT→FATAL',
      () async {
        logger.log(logging_lib.Level.FINE, 'fine');
        logger.log(logging_lib.Level.INFO, 'info');
        logger.log(logging_lib.Level.WARNING, 'warning');
        logger.log(logging_lib.Level.SEVERE, 'severe');
        logger.log(logging_lib.Level.SHOUT, 'shout');
        await OTel.loggerProvider().forceFlush();
        final sevs = exporter.records.map((r) => r.severityNumber).toSet();
        expect(
          sevs,
          containsAll(<Severity>[
            Severity.DEBUG,
            Severity.INFO,
            Severity.WARN,
            Severity.ERROR,
            Severity.FATAL,
          ]),
        );
      },
    );

    test('records exception attributes when error+stack passed', () async {
      try {
        throw StateError('boom');
      } catch (e, st) {
        logger.log(
          logging_lib.Level.SEVERE,
          'caught it',
          error: e,
          stackTrace: st,
        );
      }
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isNotEmpty);
      final rec = exporter.records.last;
      final attrMap = {
        for (final a in rec.attributes!.toList()) a.key: a.value,
      };
      expect(attrMap['exception.type'], 'StateError');
      expect(attrMap['exception.message'], contains('boom'));
    });

    test('respects zone-scoped suppression', () async {
      runWithoutSimpleLoggerInstrumentation(() {
        logger.log(logging_lib.Level.INFO, 'should not appear');
      });
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isEmpty);
    });

    test('detach restores previous onLogged', () async {
      detach();
      logger.log(logging_lib.Level.INFO, 'post-detach');
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isEmpty);
    });
  });
}

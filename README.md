# otel_simple_logger

OpenTelemetry log bridge for
[`package:simple_logger`](https://pub.dev/packages/simple_logger).

Installs an `onLogged` callback on a `SimpleLogger` that mirrors every
record into the OpenTelemetry logs pipeline. Records inherit
`trace_id` / `span_id` from the active span — log calls inside a
`Tracer.startActiveSpan` block are auto-correlated.

## Install

```yaml
dependencies:
  simple_logger: ^1.10.0
  otel_simple_logger: ^0.1.0
```

## Use

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:logging/logging.dart';
import 'package:otel_simple_logger/otel_simple_logger.dart';
import 'package:simple_logger/simple_logger.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'my-app',
  );

  final logger = SimpleLogger();
  logger.setLevel(Level.ALL);

  final detach = attachOTelSimpleLogger(logger);

  logger.log(Level.INFO, 'user signed in');

  // detach() when you want to stop forwarding.
}
```

To keep a previously-installed `onLogged` callback (e.g. a file
appender), pass `keepExisting: true`:

```dart
attachOTelSimpleLogger(logger, keepExisting: true);
```

## Severity mapping

| `package:logging` Level | OTel `severity_number` |
|-------------------------|------------------------|
| `FINEST` / `FINER`      | `TRACE`                |
| `FINE` / `CONFIG`       | `DEBUG`                |
| `INFO`                  | `INFO`                 |
| `WARNING`               | `WARN`                 |
| `SEVERE`                | `ERROR`                |
| `SHOUT`                 | `FATAL`                |

## Suppression

```dart
runWithoutSimpleLoggerInstrumentation(() {
  logger.log(Level.INFO, 'not exported to OTel');
});
```

## License

Apache 2.0 — copyright Mindful Software LLC.

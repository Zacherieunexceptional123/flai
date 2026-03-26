import 'dart:io';

import 'package:flai_cli/flai_cli.dart';

Future<void> main(List<String> args) async {
  final runner = FlaiCommandRunner();
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln('\x1B[31mError:\x1B[0m ${e.message}');
    stderr.writeln('');
    stderr.writeln(e.usage);
    exit(64);
  } catch (e) {
    stderr.writeln('\x1B[31mError:\x1B[0m $e');
    exit(1);
  }
}

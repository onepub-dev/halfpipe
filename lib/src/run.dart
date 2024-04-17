import 'dart:async';
import 'dart:io';
import 'middleware.dart';
import 'package:dcli/dcli.dart';

class Run extends Middleware<int> {
  Run(this.cmd, super.owner);

  String cmd;
  @override
  Future<Stream<List<int>>> pipe() async {
    final _fProcess = await Process.start(
      cmd,
      [],
      workingDirectory: pwd,
    );
    await _fProcess.stdout.pipe(stdout);
    await _fProcess.stderr.pipe(stderr);
    return _fProcess.stdout;
  }
}

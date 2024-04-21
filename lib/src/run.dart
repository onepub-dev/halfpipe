// import 'dart:async';
// import 'dart:io';

// import 'package:dcli/dcli.dart';

// import 'middleware.dart';

// class Run extends Middleware<int> {
//   Run(this.cmd, super.owner);

//   String cmd;
//   Future<Stream<List<int>>> pipe() async {
//     final _fProcess = await Process.start(
//       cmd,
//       [],
//       workingDirectory: pwd,
//     );
//     await _fProcess.stdout.pipe(stdout);
//     await _fProcess.stderr.pipe(stderr);
//     return _fProcess.stdout;
//   }
// }

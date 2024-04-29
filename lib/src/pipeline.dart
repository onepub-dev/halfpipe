import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';

import 'util/stream_controller_ex.dart';
/*


  Progress? progress,
  bool runInShell = false,
  bool detached = false,
  bool terminal = false,
  bool nothrow = false,
  bool privileged = false,
  String? workingDirectory,
  bool extensionSearch = true,

  progress allows us to control stdout and stderr

  bash normally pipes stdout but you can redirect stderr.

  Setup a context that controls how the script runs?


```dart 

Script.run('ls');

Script.pipeline(['ls', 'grep']);

Script.pipeline([Script.run('ls'), Script.run('grep')]);

pipeline(['ls', 'grep'])

run('ls')

withContext(() async {
  await run('ls');
  run('grep');
  serr('grep');
  sout('grep');
}, detached: true);

pipeline(() {
  run('ls');
  block(() { // script()
    print('hi');
    printerr('ho');
  })
});

/* pipeline wires streams together */
pipeline((stdin)
{
    sout(File('data.txt').openRead()); // takes the stream and attaches it to the pipe line.
    zlib.decoder
});

```
*/

// Future<void> Function(Stream<int>, Stream<int>?, Stream<int>?)
// Future<void> Function(Stream<int>, [Stream<int>?, Stream<int>?])

typedef BlockCallback = Future<void> Function(Stream<List<int>> stdin,
    StreamSink<List<int>>? stdout, StreamSink<List<int>>? stderr);

class Pipeline {
  Pipeline() {
    stdout = stdoutController.sink;
    stderr = stderrController.sink;
  }

  late final stdoutController = StreamControllerEx<List<int>>(debugName: 'stdout');
  late final StreamSink<List<int>> stdout;

  late final stderrController = StreamControllerEx<List<int>>(debugName: 'stderr');
  late final StreamSink<List<int>> stderr;

  Future<void> close() async {
    await stdoutController.close();
    await stderrController.close();

    await stdout.close();
    await stderr.close();
  }

  Future<void> run(String cmd) async {
    final _fProcess = await Process.start(
      cmd,
      [],
      workingDirectory: pwd,
    );
    await _fProcess.stdout.pipe(stdout);
    await _fProcess.stderr.pipe(stderr);
  }

  // ignore: prefer_void_to_null
  Future<void> process(BlockCallback action) async {
    await runZonedGuarded(
        () => action(stdoutController.stream, stdout, stderr), (e, st) {},
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));
  }

  void transform(Converter<List<int>, List<int>> converter) {
    stdoutController.stream.transform(converter);
  }

  void redirect(int action) {}

  static int errToOut = 1;
  static int outToErr = 2;
}

// Stream<int> block(Null Function() param0) {
// }

// void pipeline(List<int?> list) {
// }

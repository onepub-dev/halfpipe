import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';

import 'middleware.dart';
import 'pipeline.dart';
import 'run.dart';
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

class HalfPipe {

  HalfPipe() {
    stdout = stdoutController.sink;
    stderr = stderrController.sink;
  }
  List<Middleware> processors = <Middleware>[];

  Middleware<int> run(String cmd) {
    final processor = Run(cmd, this);
    processors.add(processor);
    return processor;
  }

  late final stdoutController = StreamController<List<int>>();
  late final StreamSink<List<int>> stdout;

  late final stderrController = StreamController<List<int>>();
  late final StreamSink<List<int>> stderr;

  void close() {
    stdoutController.close();
    stderrController.close();

    stdout.close();
    stderr.close();
  }

  // ignore: prefer_void_to_null
  void block(BlockCallback action) {
    runZonedGuarded(
        () => action(stdoutController.stream, stdout, stderr), (e, st) {},
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));
  }

  void redirect(int action) {}

  static int errToOut = 1;
  static int outToErr = 2;
}

// Stream<int> block(Null Function() param0) {
// }

// void pipeline(List<int?> list) {
// }


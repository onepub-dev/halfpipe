import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';
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

void main() async {
  print('start');
  HalfPipe().run('ls').transform(Transform.line)
      // .transform<String>(utf8.decoder)
      // .transform<String>(const LineSplitter())
      .block((stdin, stdout, stderr) async {
    await for (var line in stdin) {
      print('st: $line');
    }
    print('hi');
    printerr('ho');
  })
    ..redirect(Pipeline.errToOut)
    ..block((stdin, _, __) async {
      await for (var line in stdin) {
        print('2nd: $line');
      }
    });

  HalfPipe().stdin() // take input from stdin
        ..transform(zlib.decoder) // provides a stream of file entities
        ..save(pathToTempFolder) // not certain how this works.
      ;

    HalfPipe()..run('docker image ls')
    .expect(0)
    .orExpect(1)
    .orExpect(2)
    .onError((exitCode, Stream<int> error));

  HalfPipe()
    .readFile(pathToFile)
    .transform(Transform.line)
    .tee(otherHalfPipe)
    .toList();

  Cluster()
    ..start(halfPipe)
    ..start(halfPipe2)
    ..run('ls');
    ..progress([ProgressBar(), ProgressBar(indefinite:true)]);



  HalfPipe()
    ..readFile(pathToFile)
    ..transform(Transform.line)
    ..toList();

  HalfPipe()
    ..readFile(pathToFile)
    ..transform(Transform.line)
    ..take(5) // or head
    ..toList();

  HalfPipe()
    ..readFile(pathToFile)
    ..transform(Transform.line)
    ..tail(5)
    ..toList();

  HalfPipe()
    ..readFile(pathToFile)
    ..transform(Transform.line)
    ..tail(5)
    ..toParagraph();

  print('end');

  Stream<List<int>> content = File('someFile.txt').openRead();
  List<String> lines = await content
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
}

// Future<void> Function(Stream<int>, Stream<int>?, Stream<int>?)
// Future<void> Function(Stream<int>, [Stream<int>?, Stream<int>?])

typedef BlockCallback = Future<void> Function(Stream<List<int>> stdin,
    StreamSink<List<int>>? stdout, StreamSink<List<int>>? stderr);

class Middleware<T> {
  Middleware(this.owner);
  HalfPipe owner;

  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return streamTransformer.bind(this);
  }

  Middleware<R> transform<R>(StreamTransformer<T, R> streamTransformer) {
    return streamTransformer.bind(owner.stdoutController.stream);
    owner.stdoutController.stream.transform<R>(converter);

    return Middleware.copy(this);
  }

  Future<Stream<List<T>>> _pipe() {}

  Middleware.copy(Middleware other) : this.owner = other.owner;
}

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

class HalfPipe {
  List<Middleware> processors = <Middleware>[];

  HalfPipe() {
    stdout = stdoutController.sink;
    stderr = stderrController.sink;
  }

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


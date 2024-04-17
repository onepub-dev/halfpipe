import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:halfpipe/src/half_pipe.dart';
import 'package:halfpipe/src/pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('half pipe ...', () async {
    

  print('start');
  final pipe = HalfPipe()
  ..run('ls')
  // process the output of ls through a block of dart code
  ..block((stdin, stdout, stderr) async {
    await for (final line in stdin) {
      print('st: $line');
    }
    print('hi');
    printerr('ho');
  })
    ..redirect(Pipeline.errToOut)
    ..block((stdin, _, __) async {
      await for (final line in stdin) {
        print('2nd: $line');
      }
    });

withTempDir((tempDir) => 
  HalfPipe().stdin() // take input from stdin
        ..transform(zlib.decoder) // provides a stream of file entities
        ..save(tempDir) // not certain how this works.
);

    final dpipe = HalfPipe();
    dpipe.run('docker image ls');
    dpipe.expect(0)
    .orExpect(1)
    .orExpect(2)
    .onError(exitCode, Stream<int> error);

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

  final  content = File('someFile.txt').openRead();
  final  lines = await content
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  });
}
import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:halfpipe/src/half_pipe2.dart';
import 'package:halfpipe/src/pipeline.dart';
import 'package:halfpipe/src/transformers/read_file.dart';
import 'package:test/test.dart';


void main() {
  test('half pipe ...', () async {
    

  print('start');
  final pipe = HalfPipe2()
  .command('ls')
  // process the output of ls through a block of dart code
  .processor((stdin, stdout, stderr) async {
    await for (final line in stdin) {
      print('file: $line');
    }
    printerr('something went wrong');
  })
  // redirect any output to stderr back to stdout
    .redirectStderr(Redirect.toStdout)
    /// send each line to the 'rm' command - which won't work becase of the 'file: prefix
    .command('rm')
    /// A second block of dart code
    .processor((stdin, _, __) async {
      await for (final line in stdin) {
        print('2nd block: $line');
      }
    });

withTempDir((tempDir) => 
  HalfPipe2().stdin() // take input from stdin
        ..transform(zlib.decoder) // provides a stream of file entities
        ..save(tempDir) // not certain how this works.
);

    final dpipe = HalfPipe2()
    .command('docker image ls')
    .expect(0)
    .orExpect(1)
    .orExpect(2)
    .onError(exitCode, Stream<int> error);

  HalfPipe2()
    .transformer(ReadFile('path/to/file'))
    .transform(Transform.line)
    .tee(otherHalfPipe)
    .toList();

      HalfPipe2()
      .binary
    .transformer(ReadFile('path/to/file'))
    .transform(Transform.line)
    .text
    .tee(otherHalfPipe)
    .toList();

  Cluster()
    ..start(halfPipe)
    ..start(halfPipe2)
    ..run('ls');
    ..progress([ProgressBar(), ProgressBar(indefinite:true)]);



  HalfPipe2()
    .transformer(ReadFile(pathToFile))
    .toList();

  HalfPipe()
    ..transform(ReadFile(pathToFile))
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
import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart' hide touch;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/src/half_pipe2.dart';
import 'package:halfpipe/src/processors/read_file.dart';
import 'package:halfpipe/src/processors/skip.dart';
import 'package:halfpipe/src/processors/tee.dart';
import 'package:halfpipe/src/transformers/transform.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart' hide Skip;

void main() {
  test('simple command', () async {
    await withTempDirAsync((tempDir) async {
      touch('one.txt', create: true);
      touch('two.txt', create: true);
      // run ls
      final list = await HalfPipe2().command('ls')
      .toList();
      expect(list.length, equals(2));
      expect(list.first, equals('one.txt'));
      expect(list.last, equals('two.txt'));
    });
  });
  test('half pipe ...', () async {
    print('start');
    await HalfPipe2()
        .command('ls')
        // process the output of ls through a block of dart code
        .block((srcIn, srcErr, stdout, stderr) async {
          await for (final line in stdin) {
            print('file: $line');
          }
          printerr('something went wrong');
        })
        // redirect any output to stderr back to stdout
        .redirectStderr(Redirect.toStdout)

        /// send each line to the 'rm' command - which won't work
        /// becase of the 'file: prefix
        .command('rm')
        // TODO(bsutton): find some way to execute a command for each
        // line passed to a section.
        /// A second block of dart code
        .block<String>((srcIn, _, __, ___) async {
          await for (final line in srcIn) {
            print('2nd block: $line');
          }
        })
        .run();

    await withTempDirAsync((tempDir) async {
      final pathToFile = join(tempDir, 'somefile.txt');
      final pathToZip = join(tempDir, 'some.zip');
      final pipe = HalfPipe2() // process as a binary stream.
          .processor(ReadFile(pathToZip))
          .transform<int>(zlib.decoder) // provides a stream of file entities
          .write(tempDir); // not certain how this works.

      // final dpipe = HalfPipe2()
      //     .command('docker image ls')
      //     .expect(0)
      //     .orExpect(1)
      //     .orExpect(2)
      //     .onError(exitCode, error);

      await HalfPipe2()
          .processor(ReadFile('path/to/file'))
          .command('runme')
          .processor(Tee(pipe))
          .transform<String>(Transform.line)
          .block<String>((srcIn, srcErr, sinkOut, sinkErr) async {
        /// do some processing in dart.
      }).toList();

      await HalfPipe2()
          .processor(ReadFile(
              'path/to/file')) // read as binary file then use Transform.line
          .transform(Transform.line)
          .toList();

      (await HalfPipe2().processor(ReadFile(pathToFile)).toList()).take(5);

      await HalfPipe2()
          .processor(ReadFile(pathToFile))
          .transform(Transform.line)
          .processor(Skip(5))
          .toParagraph();

      print('end');

      final content = File('someFile.txt').openRead();
      await content
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();
    });
  });
}

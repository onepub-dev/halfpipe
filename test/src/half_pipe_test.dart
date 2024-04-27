import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart' hide touch;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/src/half_pipe.dart';
import 'package:halfpipe/src/processors/read_file.dart';
import 'package:halfpipe/src/processors/skip.dart';
import 'package:halfpipe/src/processors/tee.dart';
import 'package:halfpipe/src/transformers/transform.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart' hide Skip;

void main() {
  group('half_pipe', () {
    test('command with line transform', () async {
      await withTempDirAsync((tempDir) async {
        touch(join(tempDir, 'one.txt'), create: true);
        touch(join(tempDir, 'two.txt'), create: true);
        // run ls
        final list = await HalfPipe()
            .command('ls', workingDirectory: tempDir)
            .transform(Transform.line)
            .toList();
        expect(list.length, equals(2));
        expect(list.first, equals('one.txt'));
        expect(list.last, equals('two.txt'));
      });
    });
    test('block', () async {
      final list = <String>[];
      await withTempDirAsync((tempDir) async {
        touch(join(tempDir, 'one.txt'), create: true);
        touch(join(tempDir, 'two.txt'), create: true);

        await HalfPipe()
            .command('ls', workingDirectory: tempDir)
            .transform(Transform.line)
            // process the output of ls through a block of dart code
            .block<String>((srcIn, srcErr, stdout, stderr) async {
          await for (final line in srcIn) {
            list.add(line);
          }
        }).run();

        expect(list.length, equals(2));
        expect(list.first, equals('one.txt'));
        expect(list.last, equals('two.txt'));
      });
    });

    test('command and block', () async {
      await HalfPipe()
          .command('ls')
          .transform(Transform.line)
          // process the output of ls through a block of dart code
          .block((srcIn, srcErr, sinkOut, sinkErr) async {
        await for (final line in srcIn) {
          print('file: $line');
          sinkOut.add(line);
        }
        printerr('exiting block 1');
      }).block<String>((srcIn, _, __, ___) async {
        print('started block 2');
        await for (final line in srcIn) {
          print('2nd block: $line');
        }
        print('exiting block 2');
      }).run();
    });

    test('half pipe - write', () async {
      await withTempDirAsync((tempDir) async {
        final pathToFile = join(tempDir, 'somefile.txt');
        final pathToZip = join(tempDir, 'some.zip');
        final pipe = HalfPipe() // process as a binary stream.
            .processor(ReadFile(pathToZip))
            .transform<List<int>>(
                zlib.decoder) // provides a stream of file entities
            .write(tempDir); // not certain how this works.

        // final dpipe = HalfPipe2()
        //     .command('docker image ls')
        //     .expect(0)
        //     .orExpect(1)
        //     .orExpect(2)
        //     .onError(exitCode, error);

        await HalfPipe()
            .processor(ReadFile('path/to/file'))
            .command('runme')
            .processor(Tee(pipe))
            .transform<String>(Transform.line)
            .block<String>((srcIn, srcErr, sinkOut, sinkErr) async {
          /// do some processing in dart.
        }).toList();

        await HalfPipe()
            .processor(ReadFile(
                'path/to/file')) // read as binary file then use Transform.line
            .transform(Transform.line)
            .toList();

        (await HalfPipe().processor(ReadFile(pathToFile)).toList()).take(5);

        await HalfPipe()
            .processor(ReadFile(pathToFile))
            .transform(Transform.line)
            .processor<String>(Skip(5))
            .toParagraph();

        print('end');

        final content = File('someFile.txt').openRead();
        await content
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .toList();
      });
    });
  });
}

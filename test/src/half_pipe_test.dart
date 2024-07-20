import 'dart:io';

import 'package:dcli/dcli.dart' hide touch;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart' hide Skip;

import 'test_app.dart';

void main() {
  setUpAll(() async {
    expect(File(pathToTestApp).existsSync(), true);

    Logger.root.level = Level.FINE; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  });

  group('half_pipe', () {
    test('command with line transform', () async {
      await withTempDirAsync((tempDir) async {
        touch(join(tempDir, 'one.txt'), create: true);
        touch(join(tempDir, 'two.txt'), create: true);
        // run ls
        final capture = await HalfPipe()
            .command('ls', workingDirectory: tempDir)
            .transform(Transform.line)
            .captureOut();
        expect(capture.out.length, equals(2));
        expect(capture.out.first, equals('one.txt'));
        expect(capture.out.last, equals('two.txt'));
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
            .block<String>((plumbing) async {
          plumbing.src.listen(list.add);
        }).captureNone();

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
          .block((plumbing) async {
        plumbing.src.listen((line) {
          print('file: $line');
          plumbing.sink.add(line);
        });
      }).block<String>((plumbing) async {
        print('started block 2');
        plumbing.src.listen((line) {
          print('2nd block: $line');
        });
      }).captureNone();
    });

    test('half pipe - write', () async {
      await withTempDirAsync((tempDir) async {
        final pathToZip = join(tempDir, 'some.zip');
        touch(pathToZip, create: true);
        await HalfPipe() // process as a binary stream.
            .processor(ReadFile(pathToZip))
            .transform<List<int>>(
                zlib.decoder) // provides a stream of file entities
            // .writeToFile(join(tempDir, 'files.list'))
            .captureNone();
      });
    });

    test('tee', () async {
      // final list = <String>[];
      // await HalfPipe()
      //     .command('ls')
      //     .processor(Tee(list))
      //     .captureNone();
    });

    test('expect', () async {
      // final dpipe = HalfPipe2()
      //     .command('docker image ls')
      //     .expect(0)
      //     .orExpect(1)
      //     .orExpect(2)
      //     .onError(exitCode, error);
    });

    test('read', () async {
      await withTempDirAsync((tempDir) async {
        final pathToLineFile = join(tempDir, 'touch.txt');
        await File(pathToLineFile).writeAsString('''
some text
and a second line''');
        await HalfPipe()
            .processor(ReadFile(pathToLineFile))
            .command(buildTestAppCommand())
            //   .processor(Tee(pipe))
            .transform<String>(Transform.line)
            .block((plumbing) async {
          /// do some processing in dart.
        }).captureNone();
      });
    });

    test('read', () async {
      await withTempDirAsync((tempDir) async {
        final pathToLineFile = join(tempDir, 'touch.txt');
        await File(pathToLineFile).writeAsString('''
some text
and a second line''');

        await HalfPipe()
            // read as binary file then use Transform.line
            .processor(ReadFile(pathToLineFile))
            .transform(Transform.line)
            .captureNone();
      });
    });

    test('take', () async {
      await withTempDirAsync((tempDir) async {
        final pathToLineFile = join(tempDir, 'touch.txt');
        await File(pathToLineFile).writeAsString('''
some text
and a second line''');

        (await HalfPipe().processor(ReadFile(pathToLineFile)).captureOut())
            .out
            .take(5);

        (await HalfPipe()
                .processor(ReadFile(pathToLineFile))
                .transform(Transform.line)
                .processor<String>(Skip(5))
                .captureOut())
            .toParagraph();

        print('end');
      });
    });

    test('toList', () async {
      await withTempFileAsync((tempFile) async {
        tempFile.write('''
One
        Two
        Three''');
        final content = (await HalfPipe()
                .processor(ReadFile(tempFile))
                .transform(Transform.line)
                .captureOut())
            .out;

        expect(content.length, equals(3));
      });
    });
  });

  group('A group of tests', () {
    test('First Test', () async {
      await HalfPipe().command('ls').print();

      await HalfPipe().commandAndArgs('ls', args: ['-la']).print();
      await HalfPipe().command('ls -la').print();
      await HalfPipe().command('ls -la').printerr();
      await HalfPipe().command('ls -la').printmix();
      await HalfPipe().command('ls -la').captureNone();
      await HalfPipe().command('ls -la').print();
      await HalfPipe().command('ls -la').printmix();

      await HalfPipe().command('ls -la').print();
      await HalfPipe().command('ls -la').exitCode();

      await HalfPipe().command('ls -la').captureMixed()
        ..exitCode
        ..mixed;

      await HalfPipe()
          .commandAndArgs('ls',
              args: ['-la'], runInShell: true, extensionSearch: false)
          .print();
    });
  });

  test('pipeline ...', () async {
    print('start');
    await HalfPipe()
        .command('ls')
        .transform(Transform.line)
        // process the output from ls printing 'file: xxx' for each line
        .block((plumbing) async {
          plumbing.src.listen((line) {
            print('file: $line');
          });
        })
        // any data written to stderr is redirected to stdout.
        .redirectStdout(Redirect.toStdout)
        // second processor
        .block((plumbing) async {
          plumbing.src.listen((line) {
            print('2nd: $line');
          });
        })
        .print();
    print('end');
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:dcli_core/dcli_core.dart' show env;
import 'package:halfpipe/halfpipe.dart';
import 'package:halfpipe/src/transformers/utf8_line_splitter.dart';
import 'package:test/test.dart';

void main() {
  String output(Iterable<List<int>> chunks) =>
      utf8.decode(chunks.expand((chunk) => chunk).toList());

  test('redirectStdout to /dev/null suppresses captured output', () async {
    final capture = await HalfPipe()
        .commandAndArgs('/usr/bin/printf', args: ['SECRET'])
        .redirectStdout(Redirect.toDevNull)
        .captureOut();

    expect(capture.out, isEmpty);
  }, skip: Platform.isWindows);

  test('redirectStderr to /dev/null suppresses captured errors', () async {
    final capture = await HalfPipe()
        .commandAndArgs('/bin/sh', args: ['-c', 'printf SECRET >&2'])
        .redirectStderr(Redirect.toDevNull)
        .captureErr();

    expect(capture.err, isEmpty);
  }, skip: Platform.isWindows);

  test('redirectStdout to stderr forwards bytes', () async {
    final capture = await HalfPipe()
        .commandAndArgs('/usr/bin/printf', args: ['SECRET'])
        .redirectStdout(Redirect.toStderr)
        .captureErr();

    expect(output(capture.err), 'SECRET');
  }, skip: Platform.isWindows);

  test('redirectStderr to stdout forwards bytes', () async {
    final capture = await HalfPipe()
        .commandAndArgs('/bin/sh', args: ['-c', 'printf SECRET >&2'])
        .redirectStderr(Redirect.toStdout)
        .captureOut();

    expect(output(capture.out), 'SECRET');
  }, skip: Platform.isWindows);

  test('captureNone does not retain output for a later listener', () async {
    final phase = HalfPipe().commandAndArgs(
      '/usr/bin/printf',
      args: ['SECRET'],
    );
    await phase.captureNone();

    expect(await phase.sinkOutController.stream.toList(), isEmpty);
  }, skip: Platform.isWindows);

  test('print drops malformed stderr before line decoding', () async {
    final phase = HalfPipe().commandAndArgs(
      '/bin/sh',
      args: ['-c', r"printf '\377' >&2"],
    );
    expect(await phase.print(), 0);
  }, skip: Platform.isWindows);

  test('printerr drops malformed stdout before line decoding', () async {
    final phase = HalfPipe().commandAndArgs(
      '/bin/sh',
      args: ['-c', r"printf '\377'"],
    );
    expect(await phase.printerr(), 0);
  }, skip: Platform.isWindows);

  test(
    'removed environment variables are absent from child processes',
    () async {
      final original = env['HOME'];
      expect(original, isNotNull);
      env['HOME'] = null;
      try {
        final capture = await HalfPipe()
            .commandAndArgs('/usr/bin/env')
            .transform(Transform.line)
            .captureOut();
        expect(capture.out.any((line) => line.startsWith('HOME=')), isFalse);
      } finally {
        env['HOME'] = original;
      }
    },
    skip: Platform.isWindows,
  );

  test(
    'line conversion handles UTF-8 characters split across chunks',
    () async {
      final lines = await Stream<List<int>>.fromIterable([
        [0xf0, 0x9f],
        [0x98, 0x80, 0x0a],
      ]).transform(Utf8LineSplitter()).toList();

      expect(lines, ['😀']);
    },
  );

  test('malformed UTF-8 is returned as a pipeline error', () async {
    final result = HalfPipe()
        .commandAndArgs('/usr/bin/printf', args: [r'\377'])
        .transform(Transform.line)
        .captureOut();

    await expectLater(result, throwsA(isA<FormatException>()));
  }, skip: Platform.isWindows);

  test(
    'malformed UTF-8 on both streams has one handled pipeline error',
    () async {
      final phase = HalfPipe()
          .commandAndArgs(
            '/bin/sh',
            args: ['-c', r"printf '\377'; printf '\377' >&2"],
          )
          .transform(Transform.line);

      await expectLater(phase.captureMixed(), throwsA(isA<FormatException>()));
      await phase.sinkOutController.done.timeout(const Duration(seconds: 2));
      await phase.sinkErrController.done.timeout(const Duration(seconds: 2));
    },
    skip: Platform.isWindows,
  );

  test('malformed UTF-8 aborts a producer that keeps its pipes open', () async {
    final phase = HalfPipe()
        .commandAndArgs('/bin/sh', args: ['-c', r"printf '\377'; sleep 5"])
        .transform(Transform.line);
    final timer = Stopwatch()..start();

    await expectLater(
      phase.captureMixed().timeout(const Duration(seconds: 3)),
      throwsA(isA<FormatException>()),
    );
    expect(timer.elapsed, lessThan(const Duration(seconds: 2)));
    await phase.sinkOutController.done.timeout(const Duration(seconds: 2));
    await phase.sinkErrController.done.timeout(const Duration(seconds: 2));
  }, skip: Platform.isWindows);

  test('incomplete UTF-8 at EOF closes both final streams', () async {
    final phase = HalfPipe()
        .commandAndArgs('/usr/bin/printf', args: [r'\342'])
        .transform(Transform.line);

    await expectLater(phase.captureMixed(), throwsA(isA<FormatException>()));
    await phase.sinkOutController.done.timeout(const Duration(seconds: 2));
    await phase.sinkErrController.done.timeout(const Duration(seconds: 2));
  }, skip: Platform.isWindows);

  test(
    'decoder close failure stops a downstream producer before cleanup',
    () async {
      final phase = HalfPipe()
          .commandAndArgs('/usr/bin/printf', args: [r'\342'])
          .transform(Transform.line)
          .commandAndArgs('/bin/sh', args: ['-c', 'sleep 0.2; printf LATE']);

      await expectLater(
        phase.captureMixed().timeout(const Duration(seconds: 3)),
        throwsA(isA<FormatException>()),
      );
      await phase.sinkOutController.done.timeout(const Duration(seconds: 2));
      await phase.sinkErrController.done.timeout(const Duration(seconds: 2));
    },
    skip: Platform.isWindows,
  );

  test(
    'decoder error returns even if a shell child holds pipes open',
    () async {
      final phase = HalfPipe()
          .commandAndArgs('/usr/bin/printf', args: [r'\342'])
          .transform(Transform.line)
          .commandAndArgs(
            '/bin/sh',
            args: ['-c', 'trap "" TERM; (sleep 2; printf LATE) & wait'],
          );
      final timer = Stopwatch()..start();

      await expectLater(
        phase.captureMixed().timeout(const Duration(seconds: 4)),
        throwsA(isA<FormatException>()),
      );
      expect(timer.elapsed, lessThan(const Duration(milliseconds: 1900)));
      await phase.sinkOutController.done.timeout(const Duration(seconds: 2));
      await phase.sinkErrController.done.timeout(const Duration(seconds: 2));

      // The surviving child writes after the controllers have closed.
      await Future<void>.delayed(const Duration(seconds: 2));
    },
    skip: Platform.isWindows,
  );

  test('commandAndArgs preserves literal globs, quotes, and spaces', () async {
    final dir = await Directory.systemTemp.createTemp('halfpipe-argv-');
    try {
      await File('${dir.path}/one.txt').create();
      await File('${dir.path}/two.txt').create();

      final glob = await HalfPipe()
          .commandAndArgs(
            '/usr/bin/printf',
            args: ['%s\n', '*'],
            workingDirectory: dir.path,
          )
          .captureOut();
      expect(output(glob.out), '*\n');

      final quoted = await HalfPipe()
          .commandAndArgs(
            '/usr/bin/printf',
            args: ['%s|', ' "quoted" ', ' spaced '],
            workingDirectory: dir.path,
          )
          .captureOut();
      expect(output(quoted.out), ' "quoted" | spaced |');
    } finally {
      await dir.delete(recursive: true);
    }
  }, skip: Platform.isWindows);
}

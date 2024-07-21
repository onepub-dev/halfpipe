import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import '../test_app.dart';

void main() async {
  test('Test Progress', () async {
    // enableFineLogging();
    await withTempDirAsync((tempDir) async {
      final app = buildTestAppCommand(streamStdin: true);
      final sourcePath = join(tempDir, 'test.txt')
        ..write('hello world\n' * 10000, newline: '')
        ..append('quit');

      final progressMessages = <String>[];
      final size = File(sourcePath).lengthSync();
      final capture = await HalfPipe()
          .processor(ReadFile(sourcePath))
          .processor(ShowProgress(size, (processed, size) {
            final progress = '$processed / $size';
            progressMessages.add(progress);
          }))
          .command(app)
          .transform(Transform.line)
          .captureOut();
      final out = capture.out;
      expect(out.length, equals(10000));
      expect(progressMessages.length, equals(2));
      expect(progressMessages.first, equals('65536 / 120006'));
      expect(progressMessages.last, equals('120006 / 120006'));
    });
  });
}

import 'package:dcli/dcli.dart';
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import '../test_app.dart';

void main() {
  test('stdout stream ...', () async {
    await withTempDirAsync((dir) async {
      final pathToFile = join(dir, 'test.txt');
      for (var i = 0; i < 10; i++) {
        pathToFile.append('$i');
      }

      final output = await HalfPipe()
          .command('tail $pathToFile')
          .transform(Transform.line)
          .stdout
          .toList();

      expect(output.length, equals(10));
      expect(output.first, equals('0'));
      expect(output.last, equals('9'));
    });
  });

  test('stderr stream ...', () async {
    await withTempDirAsync((dir) async {
      final output = await HalfPipe()
          .command('$pathToTestApp -e 10')
          .transform(Transform.line)
          .stderr
          .toList();

      expect(output.length, equals(10));
      expect(output.first, equals('0'));
      expect(output.last, equals('9'));
    });
  });
}

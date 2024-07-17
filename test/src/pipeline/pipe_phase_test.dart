import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli_core/dcli_core.dart' as core;
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import '../logging.dart';
import '../test_app.dart';

void main() {
  test('stdout stream ...', () async {
    await core.withTempDirAsync((dir) async {
      final pathToFile = join(dir, 'test.txt');
      for (var i = 0; i < 10; i++) {
        pathToFile.append('$i');
      }

      // final output = await

      final pipe =
          HalfPipe().command('tail $pathToFile').transform(Transform.line);
      // final foutput = pipe.stdout.toList();
      // await pipe.run();
      final output = (await pipe.captureOut()).out;
      // final output = await foutput;
      expect(output.length, equals(10));
      expect(output.first, equals('0'));
      expect(output.last, equals('9'));
    });
  });

  test('stderr stream ...', () async {
    enableFineLogging();
    await core.withTempDirAsync((dir) async {
      dcli.run('dart $pathToTestApp -e 10');
      final capture = await HalfPipe()
          .command('dart $pathToTestApp -e 10')
          .transform(Transform.line)
          .captureErr();
      final output = capture.err;

      expect(output.length, equals(10));
      expect(output.first, equals('1: This is a line written to stderr'));
      expect(output.last, equals('10: This is a line written to stderr'));
    });
  });
}

import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import '../test_app.dart';

void main() async {
  test('Stream from file', () async {
    // enableFineLogging();
    await withTempDirAsync((tempDir) async {
      final app = buildTestAppCommand(streamStdin: true);
      final sourcePath = join(tempDir, 'test.txt')
        ..write('hello world\n' * 1000, newline: '')
        ..append('quit');

      final capture = await HalfPipe()
          .processor(ReadFile(sourcePath))
          // .transform(Transform.line)
          // .block<String>((plumbing) async {
          //   const counter = 0;
          //   // plumbing.srcIn.listen((data) => _log.fine(() => '2nd: ${counter++} $data'));
          //   plumbing.pipe(plumbing.src, plumbing.sink);
          //   // plumbing.pipe(plumbing.srcErr, plumbing.sinkErr);
          // })
          .command(app)
          .transform(Transform.line)
          .captureOut();
      final out = capture.out;
      expect(out.length, equals(1000));

      // return ('cat $sourcePath'
      //  | 'mysql --user $user --host=$host $schema ')
      //     .run;
    });
  });
}

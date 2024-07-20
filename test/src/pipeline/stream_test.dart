import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import '../logging.dart';
import '../test_app.dart';

void main() async {
  test('Stream from file', () async {
    enableFineLogging();
    await withTempDirAsync((tempDir) async {
      final app = buildTestAppCommand(streamStdin: true);
      final sourcePath = join(tempDir, 'test.txt')
        ..write('hello world\n' * 1000);
      final size = File(sourcePath).lengthSync();
      const written = 0;
      print('progress: ');
      final capture = await HalfPipe()
          .processor(ReadFile(sourcePath))
          .transform(Transform.line)
          .block<String>((plumbing) async {
            const last = 1;
            plumbing.srcIn.listen((data) {
              // written += data.length;

              // String? progress;
              // if (written % 1000 > last) {
              //   last = written % 1000;
              //   dcli.Terminal().column = 10;
              //   progress = '$written / $size';
              // }

              // if (written == size) {
              //   progress = '$written / $size';
              // }

              // if (progress != null) {
              //   dcli.echo('progress $progress');
              // }

              // print('progress: $written/$size');
              plumbing.sinkOut.add(data);
            });
            // plumbing.pipe(plumbing.srcErr, plumbing.sinkErr);
          })
          .block<String>((plumbing) async {
            const counter = 0;
            // plumbing.srcIn.listen((data) => print('2nd: ${counter++} $data'));
            plumbing.pipe(plumbing.srcIn, plumbing.sinkOut);
            // plumbing.pipe(plumbing.srcErr, plumbing.sinkErr);
          })
          .command(app)
          // .transform(Transform.line)
          .captureOut();
      final out = capture.out;
      expect(out.length, equals(1000));

      print('Pipeline complete');
      // return ('cat $sourcePath'
      //  | 'mysql --user $user --host=$host $schema ')
      //     .run;
    });
    print('temp dir returned');
  });
}

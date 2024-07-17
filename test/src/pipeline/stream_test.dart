import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart';

import '../logging.dart';
import '../test_app.dart';

void main() async {
  // test('Stream from file', () async {
  enableFineLogging();
  await withTempDirAsync((tempDir) async {
    final app = buildTestAppCommand(streamStdin: true);
    final sourcePath = join(tempDir, 'test.txt')..write('hello world\n' * 1000);
    final size = File(sourcePath).lengthSync();
    var written = 0;
    print('progress: ');
    await HalfPipe()
        .processor(ReadFile(sourcePath))
        .transform(Transform.line)
        .block((srcIn, srcErr, sinkOut, sinkErr) async {
      var last = 1;
      srcIn.listen((data) {
        written += data.length;

        String? progress;
        if (written % 1000 > last) {
          last = written % 1000;
          dcli.Terminal().column = 10;
          progress = '$written / $size';
        }

        if (written == size) {
          progress = '$written / $size';
        }

        if (progress != null) {
          dcli.echo('progress $progress');
        }

        // print('progress: $written/$size');
        sinkOut.add(data);
      });
      await sinkErr.addStream(srcErr);
    }).block((srcIn, srcErr, sinkOut, sinkErr) async {
      var counter = 0;
      srcIn.listen((data) => print('2nd: ${counter++} $data'));
      await sinkErr.addStream(srcErr);
    })
        // .command(app)
        .exitCode();
    // return ('cat $sourcePath'
    //  | 'mysql --user $user --host=$host $schema ')
    //     .run;
  });
  // });
}

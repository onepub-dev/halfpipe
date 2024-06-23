import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:halfpipe/src/processors/directory_list.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import '../logging.dart';

void main() {
  setUp(enableFineLogging);

  // So the problem is that we create a stream and then give it to some
  // foreign code - such as a block - and allow them to listen to the stream.
  // The issue is that we need to know when the stream we pass them is done.
  // Determining when a stream is done requires us to listen to the stream
  // but there can only be a single listener.
  // So we could ask the foriegn code to tell us when the stream is done
  // e.g waitUntilComplete would require the forign code to flag this
  // once the have finished writing data and once the input streams are empty.
  // Maybe we don't need them to tell us when the have finished writing as
  // we only care about when their output streams are empty, and the next
  // phase is responsible for that.
  // What happens if the stream is never written to, what triggers the onDone.
  // onDone is called when the stream is empty and has been closed.
  // so w
  test('directory list ...', () async {
    await withTempDirAsync((tempDir) async {
      final test1 = join(tempDir, 'test1.txt');
      final test2 = join(tempDir, 'test2.txt');
      touch(test1, create: true);
      touch(test2, create: true);
      final pathToDir = join(tempDir, 'dir');
      createDir(pathToDir);
      final test3 = join(pathToDir, 'test3.text');
      touch(test3, create: true);

      final capture = await HalfPipe()
          .processor(DirectoryList('*.*', workingDirectory: tempDir))
          .captureOut();

      expect(capture.out.length, equals(3));

      expect(capture.out, contains(test1));
      expect(capture.out, contains(test2));
      expect(capture.out, contains(test3));
    });
  });
}

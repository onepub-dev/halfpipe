import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:halfpipe/src/processors/directory_list.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

void main() {
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

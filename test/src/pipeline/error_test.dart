import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:halfpipe/src/command_exception.dart';
import 'package:test/test.dart';

import '../logging.dart';

/// Unit tests to ensure the pipeline reports errors and
/// shutsdown cleanly when an error occurs
///

void main() {
  test('stderr stream ...', () async {
    enableFineLogging();
    await withTempDirAsync((dir) async {
      var threw = false;
      try {
        await HalfPipe()
            .command('/invalid/path -e 10')
            .transform(Transform.line)
            .captureErr();
      } on CommandException catch (e, _) {
        /// good we should end up here.
        threw = true;
      }

      if (!threw) {
        fail('Expected an exception to be thrown');
      }
    });
  });
}

import 'package:dcli_core/dcli_core.dart' hide RunException;
import 'package:halfpipe/halfpipe.dart';
import 'package:halfpipe/src/command_exception.dart';
import 'package:test/test.dart';

import '../test_app.dart';

void main() {
  /// Test that the [CommandPipeSection] completes when the command completes
  /// with a 0 exit code and that it returns the apps exit code.
  /// We use the test_app.dart app to test this.
  ///
  test('CommandPipeSection completes when command exits with 0', () async {
    await withTempDirAsync((tempDir) async {
      final exitCode = await HalfPipe()
          .command(buildTestAppCommand(), workingDirectory: tempDir)
          .exitCode();

      // Assertions
      expect(exitCode, 0, reason: 'Command should exit with 0');
    });
  });

  test('CommandPipeSection completes when command exits with non-0', () async {
    await withTempDirAsync((tempDir) async {
      final commandLine = buildTestAppCommand(exitCode: 1);
      var threw = false;
      try {
        await HalfPipe()
            .command(commandLine, workingDirectory: tempDir)
            .exitCode();
      } on CommandException catch (e) {
        expect(e.exitCode, equals(1));
        expect(e.cmdLine, equals(commandLine));
        expect(
            e.reason, equals('The command exited with a non-zero exit code.'));
        threw = true;
      }
      if (threw == false) {
        fail('Expected an exception to be thrown');
      }
    });
  });
}

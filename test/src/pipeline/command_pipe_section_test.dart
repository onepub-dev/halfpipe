import 'package:dcli_core/dcli_core.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

String buildTestAppCommand(
    {int exitCode = 0, int outLines = 0, int errLines = 0}) {
  final sb = StringBuffer()
    ..write('dart ')
    ..write(join(pwd, 'test', 'src', 'test_app.dart'))
    ..write(' --exit-code $exitCode')
    ..write(' --stdout-lines $outLines')
    ..write(' --stderr-lines $errLines');

  return sb.toString();
}

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
      final exitCode = await HalfPipe()
          .command(buildTestAppCommand(exitCode: 1), workingDirectory: tempDir)
          .exitCode();

      // Assertions
      expect(exitCode, 1, reason: 'Command should exit with 1');
    });
  });
}

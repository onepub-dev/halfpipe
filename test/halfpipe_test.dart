import 'package:halfpipe/halfpipe.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      await HalfPipe.command("ls").stdout.forEach((line) {
        print(line);
      });
      HalfPipe.commandAndArgList("ls", ['-la']).print();
      HalfPipe.commandAndArgs("ls -la").print();
      HalfPipe.commandAndArgs("ls -la").printerr();
      HalfPipe.commandAndArgs("ls -la").printmix();
      HalfPipe.commandAndArgs("cat image.png").stdoutAsInt();
      HalfPipe.commandAndArgs("ls -la").print();
      HalfPipe.commandAndArgs("ls -la").printmix();

      await 'ls -la'.run;

      'ls -la'.start().print();
      'ls -la'.exitCode();

      HalfPipe.commandAndArgList("ls", ['-la'])
        ..runInShell = true
        ..detached = false
        ..terminal = true
        ..extensionSearch = false
        ..print();
    });
  });
}

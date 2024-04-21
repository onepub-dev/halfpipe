import 'package:halfpipe/src/half_pipe2.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      await HalfPipe2().command('ls').print();

      await HalfPipe2().commandAndArgs('ls', args: ['-la']).print();
      await HalfPipe2().command('ls -la').print();
      await HalfPipe2().command('ls -la').printerr();
      await HalfPipe2().command('ls -la').printmix();
      await HalfPipe2().command('cat image.png').run();
      await HalfPipe2().command('ls -la').print();
      await HalfPipe2().command('ls -la').printmix();

      await HalfPipe2().command('ls -la').print();
      await HalfPipe2().command('ls -la').exitCode();

      await HalfPipe2()
          .commandAndArgs('ls',
              args: ['-la'],
              runInShell: true,
              terminal: true,
              extensionSearch: false)
          .print();
    });
  });
}

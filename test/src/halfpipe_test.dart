import 'package:halfpipe/src/half_pipe.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      await HalfPipe().command('ls').print();

      await HalfPipe().commandAndArgs('ls', args: ['-la']).print();
      await HalfPipe().command('ls -la').print();
      await HalfPipe().command('ls -la').printerr();
      await HalfPipe().command('ls -la').printmix();
      await HalfPipe().command('cat image.png').run();
      await HalfPipe().command('ls -la').print();
      await HalfPipe().command('ls -la').printmix();

      await HalfPipe().command('ls -la').print();
      await HalfPipe().command('ls -la').exitCode();

      await HalfPipe()
          .commandAndArgs('ls',
              args: ['-la'],
              runInShell: true,
              terminal: true,
              extensionSearch: false)
          .print();
    });
  });
}

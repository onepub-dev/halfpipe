import 'package:dcli/dcli.dart';
import 'package:halfpipe/src/pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('pipeline ...', () async {
    print('start');
    final pipe = Pipeline();
    await pipe.run('ls');
    // process the output from ls printing 'file: xxx' for each line
    await pipe.process((srcIn, srcErr, sinkOut, sinkErr) async {
      await for (final line in srcIn) {
        print('file: $line');
      }
      print('hi');
      printerr('ho');
    });
    // any data written to stderr is redirected to stdout.
    pipe.redirect(Pipeline.errToOut);
    // second processor
    await pipe.process((srcIn,_, __, ___) async {
      await for (final line in srcIn) {
        print('2nd: $line');
      }
    });
    print('end');
  });
}

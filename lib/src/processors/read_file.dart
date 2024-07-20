import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import 'processor.dart';

class ReadFile extends Processor<List<int>, List<int>> {
  ReadFile(this.pathToFile);
  String pathToFile;

  final log = Logger((ReadFile).toString());

  late final _done = CompleterEx<void>(debugName: 'ReadFile');

  @override
  Future<void> addPlumbing() async {
    srcErr.stream.listen(sinkErrController.sink.add);
  }

  @override
  Future<void> start() async {
    try {
      log.fine('File size: ${File(pathToFile).lengthSync()}');
      // Read the file as a list of strings
      final fileStream = File(pathToFile).openRead();
      log.fine(() => 'opened $pathToFile');

      late StreamSubscription<List<int>> sub;

      /// write the contents of the file into the stream.
      sub = fileStream.listen((event) {
        log.fine('writing: ${event.length} bytes');
        sinkController.sink.add(event);
      })
        ..onDone(() {
          log.fine(() => 'ReadFile: onDone');
          if (!_done.isCompleted) {
            _done.complete();
          }
          sub.cancel();
          log.fine(() => 'ReadFile: sub cancelled');
        })
        ..onError(_done.completeError);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      _done.completeError(e);
    }

    return _done.future;
  }

  @override
  String get debugName => 'readfile';
}

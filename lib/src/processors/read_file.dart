import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class ReadFile extends Processor<List<int>, List<int>> {
  ReadFile(this.pathToFile);
  String pathToFile;

  late final _done = CompleterEx<void>(debugName: 'ReadFile');

  @override
  Future<void> get waitUntilComplete => _done.future;

  @override
  Future<void> start(
    StreamControllerEx<List<int>> srcIn,
    StreamControllerEx<List<int>> srcErr,
  ) async {
    try {
      // Read the file as a list of strings
      final fileStream = File(pathToFile).openRead();

      /// write the contents of the file into the stream.
      fileStream.listen((event) {
        stdout.write(event);
      })
        ..onDone(() {
          if (!_done.isCompleted) {
            _done.complete();
          }
        })
        ..onError(_done.completeError);

      await errController.sink.addStream(srcErr.stream);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      _done.completeError(e);
    }
  }

  @override
  String get debugName => 'readfile';
}

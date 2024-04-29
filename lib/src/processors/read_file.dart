import 'dart:async';
import 'dart:io';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class ReadFile extends Processor<List<int>, List<int>> {
  ReadFile(this.pathToFile);
  String pathToFile;

  @override
  Future<void> start(
    Stream<List<int>> srcIn,
    Stream<List<int>> srcErr,
  ) async {
    // Read the file as a list of strings
    final ras = File(pathToFile).open();

    /// write the contents of the file into the stream.
    ras.asStream().listen((event) {
      stdout.write(event);
    });

    await errController.sink.addStream(srcErr);
  }

  @override
  StreamControllerEx<List<int>> get errController =>
      StreamControllerEx<List<int>>(debugName: 'readfile: err');

  @override
  StreamControllerEx<List<int>> get outController =>
      StreamControllerEx<List<int>>(debugName: 'readfile: out');
}

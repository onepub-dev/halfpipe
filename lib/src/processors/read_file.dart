import 'dart:async';
import 'dart:io';

import 'processor.dart';

class ReadFile extends Processor<List<int>, List<int>> {
  ReadFile(this.pathToFile);
  String pathToFile;

  @override
  Future<void> start(Stream<List<int>> srcIn, Stream<List<int>> srcErr,
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
  StreamController<List<int>> get errController => StreamController<List<int>>();

  @override
  StreamController<List<int>> get outController => StreamController<List<int>>();
}

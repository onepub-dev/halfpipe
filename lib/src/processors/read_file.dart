import 'dart:async';
import 'dart:io';

import 'processor.dart';

class ReadFile extends Processor<int> {
  ReadFile(this.pathToFile);
  String pathToFile;

  @override
  Future<void> start(Stream<List<int>> srcIn, Stream<List<int>> srcErr,
      StreamSink<List<int>> sinkOut, StreamSink<List<int>> sinkErr) async {
    // Read the file as a list of strings
    final ras = File(pathToFile).open();

    /// write the contents of the file into the stream.
    ras.asStream().listen((event) {
      stdout.write(event);
    });

    await sinkErr.addStream(srcErr);
  }
}

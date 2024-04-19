import 'dart:io';

import 'transformer.dart';

class ReadFile implements Transformer {
  ReadFile(this.pathToFile);
  String pathToFile;

  Future<void> process(
      Stream<List<String>> stdin, IOSink stdout, IOSink stderr) async {
    // Read the file as a list of strings
    final lines = await File(pathToFile).readAsLines();

    for (final line in lines) {
      stdout.writeln(line);
    }
  }
}

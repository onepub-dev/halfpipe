import 'dart:io';

/// A provider  that can reads data from a file
/// and injects into stdout.
/// Any errors are written to stderr
class Transformer {
  void process(Stream<List<String>> stdin, IOSink stdout, IOSink stderr) {}
}

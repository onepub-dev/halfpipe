import 'dart:convert';

/// Combines a utf8.decoder and a LineSplitter into
/// a single Converter.
class Utf8LineSplitter extends Converter<List<int>, String> {
  final Utf8Decoder _utf8Decoder = const Utf8Decoder();
  final LineSplitter _lineSplitter = const LineSplitter();

  @override
  String convert(List<int> input) {
    final decodedString = _utf8Decoder.convert(input);
    final lines = _lineSplitter.convert(decodedString);
    return lines.first;
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) =>
      _Utf8LineSplitterSink(sink, _utf8Decoder, _lineSplitter);
}

class _Utf8LineSplitterSink implements Sink<List<int>> {
  _Utf8LineSplitterSink(
      this._outputSink, this._utf8Decoder, this._lineSplitter);
  final Sink<String> _outputSink;
  final Utf8Decoder _utf8Decoder;
  final LineSplitter _lineSplitter;

  @override
  void add(List<int> chunk) {
    final decodedString = _utf8Decoder.convert(chunk);
    final lines = _lineSplitter.convert(decodedString);
    for (final line in lines) {
      _outputSink.add(line);
    }
  }

  @override
  void close() {
    _outputSink.close();
  }
}

import 'dart:convert';

/// Combines a utf8.decoder and a LineSplitter into
/// a single Converter.
class Utf8LineSplitter extends Converter<List<int>, List<String>> {
  final Utf8Decoder _utf8Decoder = const Utf8Decoder();
  final LineSplitter _lineSplitter = const LineSplitter();

  @override
  List<String> convert(List<int> input) {
    final decodedString = _utf8Decoder.convert(input);
    return _lineSplitter.convert(decodedString);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<List<String>> sink) =>
      _Utf8LineSplitterSink(sink, _utf8Decoder, _lineSplitter);
}

class _Utf8LineSplitterSink implements Sink<List<int>> {
  _Utf8LineSplitterSink(
      this._outputSink, this._utf8Decoder, this._lineSplitter);
  final Sink<List<String>> _outputSink;
  final Utf8Decoder _utf8Decoder;
  final LineSplitter _lineSplitter;

  @override
  void add(List<int> chunk) {
    final decodedString = _utf8Decoder.convert(chunk);
    final lines = _lineSplitter.convert(decodedString);
    _outputSink.add(lines);
  }

  @override
  void close() {
    _outputSink.close();
  }
}

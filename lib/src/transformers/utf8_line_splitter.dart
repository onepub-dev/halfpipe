import 'dart:convert';

class Utf8LineSplitter extends Converter<List<int>, String> {
  final Utf8Decoder _utf8Decoder = const Utf8Decoder();
  final LineSplitter _lineSplitter = const LineSplitter();

  @override
  String convert(List<int> input) {
    final decodedString = _utf8Decoder.convert(input);
    final lines = _lineSplitter.convert(decodedString);
    return lines.isNotEmpty ? lines.first : '';
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

  String _carry = '';

  @override
  void add(List<int> chunk) {
    final decodedString = _carry + _utf8Decoder.convert(chunk);
    final lines = _lineSplitter.convert(decodedString);
    for (var i = 0; i < lines.length - 1; i++) {
      _outputSink.add(lines[i]);
    }
    _carry = lines.isNotEmpty ? lines.last : '';
  }

  @override
  void close() {
    if (_carry.isNotEmpty) {
      _outputSink.add(_carry);
      _carry = '';
    }
    _outputSink.close();
  }
}

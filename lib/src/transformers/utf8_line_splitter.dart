import 'dart:convert';

class Utf8LineSplitter extends Converter<List<int>, String> {
  final _utf8Decoder = const Utf8Decoder();
  final _lineSplitter = const LineSplitter();

  @override
  String convert(List<int> input) {
    final decodedString = _utf8Decoder.convert(input);
    final lines = _lineSplitter.convert(decodedString);
    return lines.isNotEmpty ? lines.first : '';
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) => _utf8Decoder
      .startChunkedConversion(_lineSplitter.startChunkedConversion(sink));
}

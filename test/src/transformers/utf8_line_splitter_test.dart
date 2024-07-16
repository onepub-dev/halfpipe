import 'dart:convert';

import 'package:halfpipe/src/transformers/utf8_line_splitter.dart';
import 'package:test/test.dart';

void main() async {
  test('split lines', () async {
    final input = Stream<List<int>>.fromIterable([
      utf8.encode('Hello\nWor'),
      utf8.encode('ld\nThis is a te'),
      utf8.encode('st\nof line splitting\n')
    ]);

    final converter = Utf8LineSplitter();
    final lineStream = input.transform(converter);

    await for (final line in lineStream) {
      print(line);
    }
  });
}

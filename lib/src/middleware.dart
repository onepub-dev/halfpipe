import 'dart:async';
import 'half_pipe.dart';

class Middleware<T> {
  Middleware(this.owner);

  Middleware.copy(Middleware other) : owner = other.owner;
  HalfPipe owner;

  // Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) => streamTransformer.bind(this);

  Middleware<R> transform<R>(StreamTransformer<T, R> streamTransformer) {
    // return streamTransformer.bind(owner.stdoutController.stream);
    owner.stdoutController.stream.transform<R>(converter);

    return Middleware.copy(this);
  }

  Future<Stream<List<T>>> _pipe() async {}
}

import 'half_pipe.dart';

class Middleware<T> {
  Middleware(this.owner);

  // static Middleware copy<R>(Middleware<R> other) => owner = other.owner;
  HalfPipe owner;

  // Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) => streamTransformer.bind(this);

  // Middleware<R> transform<R>(StreamTransformer<T, R> streamTransformer) {
  //   // return streamTransformer.bind(owner.stdoutController.stream);
  //   owner.stdoutController.stream.transform<R>(streamTransformer);

  //   return Middleware.copy(this);
  // }

  // Future<Stream<List<T>>> _pipe() async {}
}

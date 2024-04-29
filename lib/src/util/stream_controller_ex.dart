import 'dart:async';

///
/// Intended as a drop in replacement for [StreamControllerEx]
/// but with some extra support for debugging your streams.
class StreamControllerEx<T> implements StreamController<T> {
  StreamControllerEx(
      {void Function()? onListen,
      void Function()? onPause,
      void Function()? onResume,
      FutureOr<void> Function()? onCancel,
      bool sync = false,
      this.debugName}) {
    _controller = StreamController<T>(
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel,
        sync: sync);
  }

  late final StreamController<T> _controller;

  String? debugName;

  @override
  FutureOr<void> Function()? get onCancel => _controller.onCancel;

  @override
  void Function()? get onListen => _controller.onListen;

  @override
  void Function()? get onPause => _controller.onPause;

  @override
  void Function()? get onResume => _controller.onResume;

  @override
  void add(T event) {
    _controller.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<T> source, {bool? cancelOnError}) =>
      _controller.addStream(source, cancelOnError: cancelOnError);

  @override
  Future<dynamic> close() => _controller.close();

  @override
  Future<dynamic> get done => _controller.done;

  @override
  bool get hasListener => _controller.hasListener;

  @override
  bool get isClosed => _controller.isClosed;

  @override
  bool get isPaused => _controller.isPaused;

  @override
  StreamSink<T> get sink => _controller.sink;

  @override
  Stream<T> get stream => _controller.stream;

  @override
  set onCancel(FutureOr<void> Function()? _onCancel) {
    _controller.onCancel = _onCancel;
  }

  @override
  set onListen(void Function()? _onListen) {
    _controller.onListen = _onListen;
  }

  @override
  set onPause(void Function()? _onPause) {
    _controller.onPause = _onPause;
  }

  @override
  set onResume(void Function()? _onResume) {
    _controller.onResume = _onResume;
  }
}

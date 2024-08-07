import 'dart:async';

import 'package:logging/logging.dart';

// final _log = Logger('StreamControllerEx');

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
    _controller.onListen = () {
      log.fine(() => 'Listener added to : $debugName');
    };
    // _collectController(this);
  }

  final log = Logger((StreamControllerEx).toString());

  late final StreamController<T> _controller;

  String? debugName;

  static final List<StreamControllerEx<dynamic>> _activeControllers = [];
  // static Timer? _timer;

  // static void _collectController(StreamControllerEx<dynamic> controller) {
  //   _activeControllers.add(controller);
  //   _startPeriodicCheck();
  // }

  // static void _startPeriodicCheck() {
  //   _timer ??= Timer.periodic(const Duration(seconds: 15), (timer) {
  //     _checkActiveControllers();
  //   });
  // }

  // static void _checkActiveControllers() {
  //   final activeControllers =
  //       _activeControllers.where((c) => !c.isClosed).toList();
  //   if (activeControllers.isNotEmpty) {
  //     _log.fine(() => 'Active Stream Controllers:');
  //     for (final controller in activeControllers) {
  //       print(controller.debugName);
  //     }
  //   } else {
  //     _log.fine(() => 'No active stream controllers.');
  //   }
  // }

  @override
  Future<dynamic> close() {
    log.fine(() => 'closed called for $debugName');
    final f = _controller.close()
      ..whenComplete(() {
        log.fine(() => 'closed completed for $debugName');
        _activeControllers.remove(this);
      });
    return f;
  }

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
    if (_controller.isClosed) {
      throw StateError('Cannot add event after closing $debugName');
    }
    _controller.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_controller.isClosed) {
      throw StateError('Cannot add error after closing $debugName');
    }

    _controller.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<T> source, {bool? cancelOnError}) =>
      _controller.addStream(source, cancelOnError: cancelOnError);

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

  @override
  String toString() => 'StreamControllerEx($debugName)';
}

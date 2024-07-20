import 'package:logging/logging.dart';

import '../util/stream_controller_ex.dart';

mixin PipeSectionMixin<O> {
  /// This section writes any errors to this controller.
  late final _sinkErrController =
      StreamControllerEx<O>(debugName: '$debugName: err');

  /// This section writes any output to this controller.
  late final _sinkOutController =
      StreamControllerEx<O>(debugName: '$debugName: out');

  final _log = Logger((PipeSectionMixin).toString());

  StreamControllerEx<O> get sinkErrController => _sinkErrController;

  StreamControllerEx<O> get sinkOutController => _sinkOutController;

  Future<void> close() async {
    _log.fine(() =>
        'starting close of $debugName for ${_sinkOutController.debugName}');

    /// close will never complete if there are no listeners.
    if (_sinkOutController.hasListener) {
      await _sinkOutController.close();
    }
    _log
      ..fine(() => 'closed out of $debugName')
      ..fine(() =>
          'starting close of $debugName for ${_sinkErrController.debugName}');

    /// close will never complete if there are no listeners.
    if (_sinkErrController.hasListener) {
      await _sinkErrController.close();
    }
    _log.fine(
        () => 'closed err of $debugName for ${_sinkOutController.debugName}');
  }

  String get debugName;
}

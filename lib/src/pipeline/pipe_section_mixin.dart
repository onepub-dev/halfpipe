import 'package:logging/logging.dart';

import '../util/stream_controller_ex.dart';

mixin PipeSectionMixin<O> {
  late final _errController =
      StreamControllerEx<O>(debugName: '$debugName: err');
  late final _outController =
      StreamControllerEx<O>(debugName: '$debugName: out');

  final _log = Logger((PipeSectionMixin).toString());

  StreamControllerEx<O> get errController => _errController;

  StreamControllerEx<O> get outController => _outController;

  Future<void> close() async {
    _log.fine(
        () => 'starting close of $debugName for ${_outController.debugName}');

    /// close will never complete if there are no listeners.
    if (_outController.hasListener) {
      await _outController.close();
    }
    _log
      ..fine(() => 'closed out of $debugName')
      ..fine(
          () => 'starting close of $debugName for ${_errController.debugName}');

    /// close will never complete if there are no listeners.
    if (_errController.hasListener) {
      await _errController.close();
    }
    _log.fine(() => 'closed err of $debugName for ${_outController.debugName}');
  }

  String get debugName;
}

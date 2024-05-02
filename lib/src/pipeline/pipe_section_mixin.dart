import '../util/stream_controller_ex.dart';

mixin PipeSectionMixin<O> {
  late final _errController =
      StreamControllerEx<O>(debugName: '$debugName: err');
  late final _outController =
      StreamControllerEx<O>(debugName: '$debugName: out');

  StreamControllerEx<O> get errController => _errController;

  StreamControllerEx<O> get outController => _outController;

  Future<void> close() async {
    print('starting close of $debugName for ${_errController.debugName}');
    await _outController.close();
    print('closed out of $debugName');
    await _errController.close();
    print('closed err of $debugName');
  }

  String get debugName;
}

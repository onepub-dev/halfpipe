import '../util/stream_controller_ex.dart';

mixin PipeSectionMixin<O> {
  late final _errController =
      StreamControllerEx<O>(debugName: '$debugName: err');
  late final _outController =
      StreamControllerEx<O>(debugName: '$debugName: out');

  StreamControllerEx<O> get errController => _errController;

  StreamControllerEx<O> get outController => _outController;

  Future<void> close() async {
    await _outController.close();
    await _errController.close();
  }

  String get debugName;
}

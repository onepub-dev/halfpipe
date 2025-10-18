import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

typedef TapFn<I> = void Function(I data);

class Tap<I> extends Processor<I, I> {
  final TapFn<I> onData;

  final void Function()? onClose;

  final _done = CompleterEx<void>(debugName: 'Tap');

  Tap(this.onData, {this.onClose});

  @override
  Future<void> addPlumbing() async {
    src.stream.listen((data) {
      onData(data);
      sinkController.sink.add(data);
    }, onDone: () {
      onClose?.call();
      if (!_done.isCompleted) {
        _done.complete();
      }
    }, onError: (Object e, StackTrace st) {
      if (!_done.isCompleted) {
        _done.completeError(e, st);
      }
    });

    srcErr.stream.listen(
      sinkErrController.sink.add,
      onError: (Object e, StackTrace st) =>
          sinkErrController.sink.addError(e, st),
    );
  }

  @override
  Future<void> start() => _done.future;

  @override
  String get debugName => 'tap';
}

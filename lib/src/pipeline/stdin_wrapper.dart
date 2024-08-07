import 'dart:async';
import 'dart:io';

import '../util/stream_controller_ex.dart';

// final _log = Logger('StdinWrapper');

/// Runs [callback] with access to [stdin] for the duration of the
/// call.
/// Using this method allows multiple [callback]s to sequentially
/// access [stdin] without throwing an error.
Future<void> withStdin(
    Future<void> Function(StreamControllerEx<List<int>>) callback,
    {String? debugName}) async {
  final wrapper = StdinWrapper();
  final controller =
      StreamControllerEx<List<int>>(debugName: debugName ?? 'wrapped stdin');

  wrapper.stdinControllers.add(controller);
  try {
    await callback(controller);
  } finally {
    wrapper.stdinControllers.remove(controller);
  }
}

/// Stdin can only be listened to once but we allow users to create
/// multiple pipelines and each needs the ability to dip into
/// stdin at the point in time they run.
/// As stdin is a single stream this won't work as it can only be listended to
/// once.
/// This wrapper allows multiple listeners to subscribe to stdin and distributes
/// the events to all listeners.
///
class StdinWrapper {
  factory StdinWrapper() => _stdinWrapper;

  StdinWrapper._internal() {
    /// distribute stdin events to all active controllers.
    // subscription =
    stdin.listen((event) {
      for (final controller in stdinControllers) {
        controller.sink.add(event);
      }
    });
  }

  // late final StreamSubscription<List<int>> subscription;

  final stdinControllers = <StreamControllerEx<List<int>>>[];
  static final StdinWrapper _stdinWrapper = StdinWrapper._internal();
}

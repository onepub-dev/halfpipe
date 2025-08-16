// part of the public api
// ignore_for_file: omit_obvious_property_types

import 'pipe_phase.dart';

/// A [Capture] is returned from the the 'capture' terminal
/// function on a [PipePhase].
/// When you call 'capture' output from the pipeline is
/// captured and returned as a [Capture].
///
/// @author bsutton

/// Base class of all of the CaptureXXX classes.
abstract class Capture {
  String toParagraph();
  late final int exitCode;
}

/// Both Out and Err are captured into separate lists
class CaptureBoth<T> implements Capture {
  List<T> out = <T>[];
  List<T> err = <T>[];
  @override
  late final int exitCode;

  /// Runs the pipeline outputing the results to a paragraph of
  /// text containing newlines.
  @override
  String toParagraph() {
    final list = [...out, ...err];
    return list.join('\n');
  }
}

/// Only Out is captured into a list.
class CaptureOut<T> implements Capture {
  List<T> out = <T>[];
  @override
  late final int exitCode;

  /// Outputs the captured data as a single paragraph of text.
  ///
  @override
  String toParagraph() => out.join('\n');
}

/// Only Err is captured into a list.
class CaptureErr<T> implements Capture {
  List<T> err = <T>[];
  @override
  late final int exitCode;

  /// Outputs the captured data as a single paragraph of text.
  ///
  @override
  String toParagraph() => err.join('\n');
}

/// Both Out and Err are captured into a single list.
class CaptureMixed<T> implements Capture {
  List<T> mixed = <T>[];
  @override
  late final int exitCode;

  /// Outputs the captured data as a single paragraph of text.
  ///
  @override
  String toParagraph() => mixed.join('\n');
}

class CaptureNone<T> implements Capture {
  @override
  late final int exitCode;

  CaptureNone(this.exitCode);

  @override
  String toParagraph() => '';
}

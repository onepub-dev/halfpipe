/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli_common/dcli_common.dart';
import 'package:stack_trace/stack_trace.dart';

/// Thrown when any of the process related method
/// such as .run and .start fail.
class RunException extends DCliException {
  ///
  RunException(
    this.cmdLine,
    this.exitCode,
    this.reason, {
    Trace? stackTrace,
  }) : super(reason, stackTrace);

  ///
  RunException.withArgs(
    String? cmd,
    List<String?> args,
    this.exitCode,
    this.reason, {
    Trace? stackTrace,
  })  : cmdLine = '$cmd ${args.join(' ')}',
        super(reason, stackTrace);

  /// The command line that was being run.
  String cmdLine;

  /// the exit code of the command.
  int? exitCode;

  /// the error.
  String reason;

  @override
  String get message => '''
$cmdLine 
exit: $exitCode
reason: $reason''';
}

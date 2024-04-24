import 'dart:convert';

import 'package:dcli/dcli.dart';

import 'half_pipe.dart';
import 'pipeline/pipe_phase.dart';
import 'transformers/transform.dart';

/// Typedef for LineActions
typedef LineAction = void Function(String line);

/// Typedef for cancellable LineActions.
typedef CancelableLineAction = bool Function(String line);

void _noOpAction(String line) {}

extension StringAsProcess on String {
  /// run
  Future<void> get run async {
    await HalfPipe().commandAndArgs(this).print();
  }

  /// start
  PipePhase<int> start({
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) =>
      HalfPipe().commandAndArgs(this,
          workingDirectory: workingDirectory,
          runInShell: runInShell,
          detached: detached,
          terminal: terminal,
          nothrow: nothrow,
          extensionSearch: extensionSearch);

  /// foreach
  Future<void> forEach(
    LineAction stdout, {
    LineAction stderr = _noOpAction,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) async {
    final pipe = HalfPipe()
        .commandAndArgs(this,
            workingDirectory: workingDirectory,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            extensionSearch: extensionSearch)
        .block((srcIn, srcErr, sinkOut, sinkErr) async {
      srcIn.listen(print);
      srcErr.listen(printerr);
    });
    pipe.stdout.listen(print);
    pipe.stderr.listen(printerr);

    await pipe.run();
  }

  Future<List<String>> toList(
    String commandAndArgs, {
    int skipLines = 0,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) async {
    final lines = <String>[];

    final pipe = HalfPipe()
        .commandAndArgs(commandAndArgs,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            workingDirectory: workingDirectory,
            extensionSearch: extensionSearch)
        .transform(Transform.line as Converter<int, dynamic>);

    (await pipe.stdmix).listen((lines) => lines.addAll(lines));

    return lines.sublist(skipLines);
  }

  Future<String> toParagraph({
    int skipLines = 0,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) async =>
      (await toList(
        this,
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        nothrow: nothrow,
        workingDirectory: workingDirectory,
        extensionSearch: extensionSearch,
      ))
          .join(eol);

  Future<String?> get firstLine async {
    final lines = await toList(this);

    String? line;
    if (lines.isNotEmpty) {
      line = lines[0];
    }

    return line;
  }

  Future<int> exitCode({
    int skipLines = 0,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) =>
      start(
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        nothrow: nothrow,
        workingDirectory: workingDirectory,
        extensionSearch: extensionSearch,
      ).exitCode();
}

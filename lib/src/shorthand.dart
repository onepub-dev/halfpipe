import 'package:dcli/dcli.dart';

import 'half_pipe.dart';
import 'pipeline/pipe_phase.dart';
import 'transformers/transform.dart';

/// Typedef for LineActions
typedef LineAction = void Function(String line);

/// Typedef for cancellable LineActions.
typedef CancelableLineAction = bool Function(String line);

void _noOpAction(String line) {}

extension StringAsPipeline on String {
  /// run
  Future<void> get run async {
    await HalfPipe().commandAndArgs(this).print();
  }

  /// start
  PipePhase<List<int>> start({
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
    await HalfPipe()
        .commandAndArgs(this,
            workingDirectory: workingDirectory,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            extensionSearch: extensionSearch)
        .transform(Transform.line)
        .block<String>((plumbing) async {
      plumbing.srcIn.listen((line) => stdout(line));
      plumbing.srcErr.listen((line) => stderr(line));
    }).captureNone();
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
    final capture = HalfPipe()
        .commandAndArgs(commandAndArgs,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            workingDirectory: workingDirectory,
            extensionSearch: extensionSearch)
        .transform(Transform.line)
        .captureMixed();

    final lines = (await capture).mixed;

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

import 'package:dcli_core/dcli_core.dart';

import '../halfpipe.dart';

/// Typedef for LineActions
typedef LineAction = void Function(String line);

/// Typedef for cancellable LineActions.
typedef CancelableLineAction = bool Function(String line);

void _noOpAction(String line) {}

extension StringAsProcess on String {
  /// run
  Future<void> get run async {
    await HalfPipe.commandAndArgs(this).print();
  }

  /// start
  HalfPipeHasCommand start({
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) =>
      HalfPipe.commandAndArgs(this)
        ..workingDirectory = workingDirectory
        ..runInShell = runInShell
        ..detached = detached
        ..terminal = terminal
        ..nothrow = nothrow
        ..extensionSearch = extensionSearch;

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
    final pipe = HalfPipe.commandAndArgs(this)
      ..workingDirectory = workingDirectory
      ..runInShell = runInShell
      ..detached = detached
      ..terminal = terminal
      ..nothrow = nothrow
      ..extensionSearch = extensionSearch;
    await pipe.stdout.forEach((line) => stdout(line));
    await pipe.stderr.forEach((line) => stderr(line));
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

    final pipe = HalfPipe.commandAndArgs(commandAndArgs)
      ..runInShell = runInShell
      ..detached = detached
      ..terminal = terminal
      ..nothrow = nothrow
      ..workingDirectory = workingDirectory
      ..extensionSearch = extensionSearch;

    await pipe.stdmix.forEach(lines.add);

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

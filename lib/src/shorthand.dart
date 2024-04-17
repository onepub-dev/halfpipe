import 'dart:io';

import '../halfpipe.dart';
import 'platform.dart';

/// Typedef for LineActions
typedef LineAction = void Function(String line);

/// Typedef for cancellable LineActions.
typedef CancelableLineAction = bool Function(String line);

void _noOpAction(String line) {}

extension StringAsProcess on String {
  /// run
  Future<void> get run async {
    HalfPipe.commandAndArgs(this).print();
  }

  /// start
  HalfPipeHasCommand start({
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) {
    return HalfPipe.commandAndArgs(this)
      ..workingDirectory = workingDirectory
      ..runInShell = runInShell
      ..detached = detached
      ..terminal = terminal
      ..nothrow = nothrow
      ..extensionSearch = extensionSearch;
  }

  /// foreach
  void forEach(
    LineAction stdout, {
    LineAction stderr = _noOpAction,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) {
    HalfPipe.commandAndArgs(this)
      ..workingDirectory = workingDirectory
      ..runInShell = runInShell
      ..detached = detached
      ..terminal = terminal
      ..nothrow = nothrow
      ..extensionSearch = extensionSearch
      ..stdout.forEach((line) => stdout(line))
      ..stderr.forEach((line) => stderr(line));
  }

  List<String> toList(
    String commandAndArgs, {
    int skipLines = 0,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) {
    var lines = <String>[];

    HalfPipe.commandAndArgs(commandAndArgs)
      ..runInShell = runInShell
      ..detached = detached
      ..terminal = terminal
      ..nothrow = nothrow
      ..workingDirectory = workingDirectory
      ..extensionSearch = extensionSearch
      ..stdmix.forEach((line) => lines.add(line));

    return lines.sublist(skipLines);
  }

  String toParagraph({
    int skipLines = 0,
    String? workingDirectory,
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool nothrow = false,
    bool extensionSearch = true,
  }) =>
      toList(
        this,
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        nothrow: nothrow,
        workingDirectory: workingDirectory,
        extensionSearch: extensionSearch,
      ).join(Platform().eol);

  String? get firstLine {
    final lines = toList(this);

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

// ignore_for_file: avoid_setters_without_getters, one_member_abstracts

import 'dart:async';
import 'half_pipe_stream.dart';

abstract class HalfPipeHasCommand implements HalfPipeStream {
  set workingDirectory(String? workingDirectory) {}

  set extensionSearch(bool extensionSearch) {}

  set terminal(bool terminal) {}

  set runInShell(bool runInShell) {}

  set detached(bool detached) {}

  set nothrow(bool nothrow) {}

  void addArgs(String args);

  void addArgList(List<String> args);

  Future<int> exitCode();
}

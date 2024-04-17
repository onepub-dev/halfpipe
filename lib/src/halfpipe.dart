import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:core' as core;
import 'dart:io';

import 'package:dcli_common/dcli_common.dart' as common;

import 'parse_cli_command.dart';
import 'run_process.dart';

enum ArgMethod { command, commandAndArgs, commandAndList }

class HalfPipe implements HalfPipeHasCommand {
// class HalfPipeBuilder implements HelpPipeHasCommand {
  String? _command;
  final List<String> _argList = <String>[];

  String? _commandAndArgs;

  ArgMethod argMethod;

  String? workingDirectory;

  bool runInShell = false;
  bool detached = false;
  bool terminal = false;
  bool extensionSearch = true;
  bool nothrow = true;

  HalfPipe._command(String command) : argMethod = ArgMethod.command;

  HalfPipe._commandAndArgList(String command, List<String> args)
      : argMethod = ArgMethod.commandAndList;

  HalfPipe._commandAndArgs(String commandAndArgs)
      : argMethod = ArgMethod.commandAndArgs {
    _commandAndArgs = commandAndArgs;
  }

  static HalfPipeHasCommand command(String command) {
    return HalfPipe._command(command);
  }

  static HalfPipeHasCommand commandAndArgList(
      String command, List<String> args) {
    return HalfPipe._commandAndArgList(command, args);
  }

  static HalfPipeHasCommand commandAndArgs(String commandAndArgs) {
    return HalfPipe._commandAndArgs(commandAndArgs);
  }

  @override
  void addArgList(List<String> args) {
    _argList.addAll(args);
  }

  @override
  void addArgs(String args) {
    _commandAndArgs = _commandAndArgs! + args;
  }

  @override
  Stream<String> get stdout async* {
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      progress.addToStdout(line);
    }).onDone(() {
      _stdoutFlushed.complete();
      _stdoutCompleter.complete(true);
    });
  }

  void _start() {
    final process = RunProcess().start(this);
  }

  @override
  Stream<String> get stderr {
    throw UnimplementedError();
  }

  @override
  Stream<String> get stdmix {
    throw UnimplementedError();
  }

  @override
  Stream<List<int>> stdoutAsInt() async* {}
  @override
  Stream<List<int>> stderrAsInt() async* {}
  @override
  Stream<List<int>> stdmixAsInt() async* {}

  @override
  Future<void> print() async {
    await stdout.forEach((line) {
      core.print(line);
    });
  }

  @override
  Future<void> printerr() async {
    await stdout.forEach((line) {
      common.printerr(line);
    });
  }

  @override
  Future<void> printmix() async {
    await stdmix.forEach((line) {
      core.print(line);
    });
  }

  @override
  Future<int> exitCode() {
    throw UnimplementedError();
  }

  ParsedCliCommand parse() {
    ParsedCliCommand parsed;

    switch (argMethod) {
      case ArgMethod.command:
        parsed = ParsedCliCommand.fromArgList(
            _command!, <String>[], workingDirectory);
        break;
      case ArgMethod.commandAndArgs:
        parsed = ParsedCliCommand(_commandAndArgs!, workingDirectory);
        break;
      case ArgMethod.commandAndList:
        parsed =
            ParsedCliCommand.fromArgList(_command!, _argList, workingDirectory);
        break;
    }

    return parsed;
  }

  void wireStreams(Process process) {
    /// handle stdout stream
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      progress.addToStdout(line);
    }).onDone(() {
      _stdoutFlushed.complete();
      _stdoutCompleter.complete(true);
    });

    // handle stderr stream
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      progress.addToStderr(line);
    }).onDone(() {
      _stderrFlushed.complete();
      _stderrCompleter.complete(true);
    });
  }
}

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

abstract class HalfPipeHasArgs {
  void addArgs(String args);
}

abstract class HalfPipeHasArgList {
  void addArgsList(List<String> args);
}

abstract class HalfPipeStream {
  Stream<String> get stdout async* {}
  Stream<String> get stderr async* {}
  Stream<String> get stdmix async* {}

  Stream<List<int>> stdoutAsInt() async* {}
  Stream<List<int>> stderrAsInt() async* {}
  Stream<List<int>> stdmixAsInt() async* {}

  Future<void> print();
  Future<void> printerr();
  Future<void> printmix();
}

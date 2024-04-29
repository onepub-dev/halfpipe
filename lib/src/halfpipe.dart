// // ignore_for_file: avoid_setters_without_getters, one_member_abstracts

// import 'dart:async';
// import 'dart:convert';
// import 'dart:core' as core;
// import 'dart:core';
// import 'dart:io';

// // import 'package:dcli_common/dcli_common.dart' as common;

// import 'package:dcli/dcli.dart';

// import 'half_pipe_has_command.dart';
// import 'half_pipe_stream.dart';
// import 'parse_cli_command.dart';
// import 'run_process.dart';



// class HalfPipe implements HalfPipeHasCommand {
//   HalfPipe._command(String command) : argMethod = ArgMethod.command;

//   HalfPipe._commandAndArgList(String command, List<String> args)
//       : argMethod = ArgMethod.commandAndList;

//   HalfPipe._commandAndArgs(String commandAndArgs)
//       : argMethod = ArgMethod.commandAndArgs {
//     _commandAndArgs = commandAndArgs;
//   }
//   final _stderrFlushed = Completer<bool>();
//   final _stdoutFlushed = Completer<bool>();

// // class HalfPipeBuilder implements HelpPipeHasCommand {
//   String? _command;
//   final List<String> _argList = <String>[];

//   String? _commandAndArgs;

//   ArgMethod argMethod;

//   String? workingDirectory;

//   bool runInShell = false;
//   bool detached = false;
//   bool terminal = false;
//   bool extensionSearch = true;
//   bool nothrow = true;

//   static HalfPipeHasCommand command(String command) =>
//       HalfPipe._command(command);

//   static HalfPipeHasCommand commandAndArgList(
//           String command, List<String> args) =>
//       HalfPipe._commandAndArgList(command, args);

//   static HalfPipeHasCommand commandAndArgs(String commandAndArgs) =>
//       HalfPipe._commandAndArgs(commandAndArgs);

//   @override
//   void addArgList(List<String> args) {
//     _argList.addAll(args);
//   }

//   @override
//   void addArgs(String args) {
//     _commandAndArgs = _commandAndArgs! + args;
//   }

//   @override
//   Stream<String> get stdout async* {
//     process.stdout
//         .transform(utf8.decoder)
//         .transform(const LineSplitter())
//         .listen(progress.addToStdout)
//         .onDone(_stdoutFlushed.complete);
//   }

//   Future<void> _start() async {
//     await RunProcess().start(halfPipe: this);
//   }

//   @override
//   Stream<String> get stderr {
//     throw UnimplementedError();
//   }

//   @override
//   Stream<String> get stdmix {
//     throw UnimplementedError();
//   }

//   @override
//   Stream<List<int>> stdoutAsInt() async* {}
//   @override
//   Stream<List<int>> stderrAsInt() async* {}
//   @override
//   Stream<List<int>> stdmixAsInt() async* {}

//   @override
//   Future<void> print() async {
//     await stdout.forEach(core.print);
//   }

//   @override
//   Future<void> printerr() async {
//     await stdout.forEach(common.printerr);
//   }

//   @override
//   Future<void> printmix() async {
//     await stdmix.forEach(core.print);
//   }

//   @override
//   Future<int> exitCode() {
//     throw UnimplementedError();
//   }

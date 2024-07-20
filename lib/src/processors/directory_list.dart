import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';
import 'package:dcli_core/dcli_core.dart';

import 'processor.dart';

enum FileEntityTypes { file, directory, link }

/// Used to inject a list of paths from the local file
/// system into the pipeline.
///
/// Currently this processor runs synchronously meaning that
/// it will run to completion before the next pipe
/// section is run.
///
/// Note that the error stream will not pass through this
/// processor.
///P
class DirectoryList<I> extends Processor<I, String> {
  DirectoryList(this.pattern,
      {this.workingDirectory = '.',
      this.recursive = true,
      this.caseSensitive = false,
      this.includeHidden = false,
      this.types = const [FileEntityTypes.file]});
  String pattern;
  String workingDirectory;
  bool recursive;
  bool caseSensitive;
  bool includeHidden;
  List<FileEntityTypes> types;

  late final _done = CompleterEx<void>(debugName: 'DirectoryList');

  @override
  Future<void> start() async {
    try {
      await for (final file in findAsync(pattern,
          workingDirectory: workingDirectory,
          recursive: recursive,
          caseSensitive: caseSensitive,
          includeHidden: includeHidden,
          types: types.map(_map).toList())) {
        sinkOutController.sink.add(file.pathTo);
      }
      _done.complete();
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      _done.completeError(e);
    }
    return _done.future;
  }

  @override
  String get debugName => 'DirectoryList';

  FileSystemEntityType _map(FileEntityTypes type) => switch (type) {
        FileEntityTypes.file => FileSystemEntityType.file,
        FileEntityTypes.directory => FileSystemEntityType.directory,
        FileEntityTypes.link => FileSystemEntityType.link,
      };

  @override
  Future<void> addPlumbing() async {
    // NOOP
  }
}

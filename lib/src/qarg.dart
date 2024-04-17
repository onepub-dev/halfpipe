import 'dart:io';

import 'package:dcli_core/dcli_core.dart';
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';

/// TODO: consider replacing with code from the dart sdk:
/// https://github.com/dart-lang/io/blob/master/lib/src/shell_words.dart
class QArg {
  QArg(String iarg) {
    wasQuoted = false;
    arg = iarg.trim();

    if (arg.startsWith('"') && arg.endsWith('"')) {
      wasQuoted = true;
    }
    if (arg.startsWith("'") && arg.endsWith("'")) {
      wasQuoted = true;
    }

    if (wasQuoted!) {
      arg = arg.substring(1, arg.length - 1);
    }
  }

  QArg.fromParsed(this.arg, {required this.wasQuoted});

  bool? wasQuoted;
  late String arg;

  /// We only do glob expansion if the arg contains at least one of
  /// *, [, ?
  ///
  /// Note: under Windows powershell does perform glob expansion so we need
  /// to supress glob expansion.
  bool get needsExpansion =>
      !Settings().isWindows &&
      (arg.contains('*') || arg.contains('[') || arg.contains('?'));

  static List<QArg> translate(List<String?> args) {
    final qargs = <QArg>[];
    for (final arg in args) {
      final qarg = QArg(arg!);
      qargs.add(qarg);
    }
    return qargs;
  }

  Iterable<String> expandGlob(String? workingDirectory) {
    final expanded = <String>[];
    if (arg.contains('~')) {
      arg = arg.replaceAll('~', HOME);
    }
    if (needsExpansion) {
      final files = _expandGlob(workingDirectory!);

      /// translate the files to relative paths if appropriate.
      for (var file in files) {
        if (isWithin(workingDirectory, file!)) {
          file = relative(file, from: workingDirectory);
        }
        expanded.add(file);
      }
    } else {
      expanded.add(arg);
    }
    return expanded;
  }

  Iterable<String?> _expandGlob(String workingDirectory) {
    final glob = Glob(arg);

    /// we are interested in the last part of the arg.
    /// e.g. of  path/.* we want the .*
    final includeHidden = basename(arg).startsWith('.');

    var files = <FileSystemEntity>[];

    files = glob.listFileSystemSync(
      const LocalFileSystem(),
      root: workingDirectory,
    );

    if (files.isEmpty) {
      // if no matches the bash spec says return
      // the original arg.
      return [arg];
    } else {
      return files
          .where((f) => includeHidden || !isHidden(workingDirectory, f))
          .map((f) => f.path);
    }
  }

  // check if the entity is a hidden file (.xxx) or
  // if lives in a hidden directory.
  bool isHidden(String workingDirectory, FileSystemEntity entity) {
    final relativePath =
        truepath(relative(entity.path, from: workingDirectory));

    final parts = relativePath.split(separator);

    var isHidden = false;
    for (final part in parts) {
      if (part.startsWith('.')) {
        isHidden = true;
        break;
      }
    }
    return isHidden;
  }
}

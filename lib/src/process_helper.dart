import 'package:dcli_core/dcli_core.dart';
import 'package:dcli_filesystem/dcli_filesystem.dart';
import 'package:path/path.dart';

Future<String> searchForCommandExtension(
    String cmd, String? workingDirectory) async {
  // if the cmd has an extension they we don't need to find
  // its extension.
  if (extension(cmd).isNotEmpty) {
    return cmd;
  }

  // if the cmd has a path then
  // we only search the cmd's directory
  if (dirname(cmd) != '.') {
    final resolvedPath = join(workingDirectory ?? '.', dirname(cmd));
    return _findExtension(basename(cmd), resolvedPath);
  }

  // just the cmd so run which with searchExtension.
  var whichResult = await which(cmd);
  return basename(whichResult.path ?? cmd);
}

///  Searches for a file in [workingDirectory] that matches [basename]
///  with one of the defined Windows extensions
String _findExtension(String basename, String workingDirectory) {
  for (final extension in env['PATHEXT']!.split(';')) {
    final cmd = '$basename$extension';
    if (exists(join(workingDirectory, cmd))) {
      return cmd;
    }
  }
  return basename;
}

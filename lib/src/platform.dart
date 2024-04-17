/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli_common/dcli_common.dart';

/// Extensions for the Platform class
extension PlatformEx on Platform {
  /// Returns the OS specific End Of Line (eol) character.
  /// On Windows this is '\r\n' on all other platforms
  /// it is '\n'.
  /// Usage: Platform().eol
  ///
  /// Note: you must import both:
  /// ```dart
  /// import 'dart:io';
  /// import 'package:dcli/dcli.dart';
  /// ```
  String get eol => DCliPlatform().isWindows ? '\r\n' : '\n';
}

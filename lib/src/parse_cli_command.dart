/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli_core/dcli_core.dart';
import 'package:dcli_filesystem/dcli_filesystem.dart';
import 'package:halfpipe/src/run_exception.dart';

import 'qarg.dart';

/// Class to parse a OS command, contained in a string, which we need to pass
/// into the dart Process.start method as a application name and a series
/// of arguments.
class ParsedCliCommand {
  ///
  ParsedCliCommand(String command, String? workingDirectory) {
    workingDirectory ??= pwd;
    if (!exists(workingDirectory)) {
      throw RunException(
        command,
        -1,
        "The workingDirectory ${truepath(workingDirectory)} doesn't exists.",
      );
    }
    final qargs = _parse(command);
    args = _expandGlobs(qargs, workingDirectory);
  }

  /// when passed individual args we respect any quotes that are
  /// passed as they have been put there with intent.
  ParsedCliCommand.fromArgList(
    this.cmd,
    List<String> rawArgs,
    String? workingDirectory,
  ) {
    workingDirectory ??= pwd;
    if (!exists(workingDirectory)) {
      throw RunException(
        '$cmd ${rawArgs.join(' ')}',
        -1,
        "The workingDirectory ${truepath(workingDirectory)} doesn't exists.",
      );
    }

    final qargs = QArg.translate(rawArgs);
    args = _expandGlobs(qargs, workingDirectory);
  }

  /// The commdand that we parsed from the command line
  late String cmd;

  /// The args that we parsed from the command line
  List<String> args = <String>[];

  /// The escape character use for command lines
  static const escapeCharacter = '^';

  /// parses the given command breaking them done into words
  List<QArg> _parse(String commandLine) {
    final parts = <QArg>[];

    /// The stack helps us deal with nest quotes.
    final stateStack = StackList<_ParseFrame>();
    var currentState = _ParseFrame(_ParseState.searching, -1);

    /// The current word we are adding characters to.
    var currentWord = '';

    for (var i = 0; i < commandLine.length; i++) {
      final char = commandLine[i];

      switch (currentState.state) {
        case _ParseState.searching:
          // ignore leading space.
          if (char == ' ') {
            break;
          }

          /// single or double quote puts us into inQuote mode
          if (char == '"' || char == "'") {
            stateStack.push(currentState);
            currentState = _ParseFrame.forQuote(stateStack, i, char);
            break;
          }

          /// ^ is our escape character.
          /// Put us into escape mode to escape the next character.
          if (char == escapeCharacter) {
            stateStack.push(currentState);
            currentState = _ParseFrame(_ParseState.escaped, i);
            break;
          }

          /// a normal character so must be the start of a word.
          stateStack.push(currentState);
          currentState = _ParseFrame(_ParseState.inWord, i);

          currentWord += char;
          break;

        /// if we are in escape mode.
        case _ParseState.escaped:
          currentState = stateStack.pop();

          /// if we were in searching mode then
          /// this character indicates the start of a word.
          if (currentState.state == _ParseState.searching) {
            stateStack.push(currentState);
            currentState = _ParseFrame(_ParseState.inWord, i);
          }
          currentWord += char;
          break;

        case _ParseState.inWord:

          /// A space indicates the end of a word.
          /// If it is inside a quote then we would be inQuote mode.
          // added ignore as lint has a bug for conditional in a
          // switch statement #27
          // ignore: invariant_booleans
          if (char == ' ') {
            // a non-escape/non-quoted space means a new part.
            currentState = stateStack.pop();
            if (currentState.state == _ParseState.searching) {
              parts.add(QArg(currentWord));
              currentWord = '';
            } else {
              currentWord += char;
            }
            break;
          }

          /// The escape character so put us into
          /// escape mode so the escaped character will
          /// be treated as a normal char.
          // added ignore as lint has a bug for conditional in a
          // switch statement #27
          // ignore: invariant_booleans
          if (char == escapeCharacter) {
            stateStack.push(currentState);
            currentState = _ParseFrame(_ParseState.escaped, i);
            break;
          }

          /// quoted text in a word is treated as
          /// part of the same word but we still
          /// strip the quotes to match bash
          if (char == '"' || char == "'") {
            stateStack.push(currentState);
            currentState = _ParseFrame.forQuote(stateStack, i, char);
          } else {
            currentWord += char;
          }
          break;

        /// we are in a quote so just suck in
        /// characters until we see a matching quote.
        ///
        /// scenarios

        // "hi"
        // We are in a quote, parent is searching so strip quote
        //
        // hi="one"
        // We are in a quote, parent is word so keep the quote
        //
        // "abc 'one'"
        // If nested always keep the quote
        // If last quote if parent searching strip quote.
        //
        // hi="abc 'one'"
        // If parent is quote then keep quote
        // if parent is word then keep quote

        case _ParseState.inQuote:
          if (char == currentState.matchingQuote) {
            currentState = stateStack.pop();
            final state = currentState.state;

            // If we were searching or inWord then this will end the word
            if (state == _ParseState.searching || state == _ParseState.inWord) {
              /// If we are in a word then the quote also ends the word.
              if (state == _ParseState.inWord) {
                currentState = stateStack.pop();
              }

              parts.add(QArg.fromParsed(currentWord, wasQuoted: true));
              currentWord = '';
            }
            break;
          }

          /// The escape character so put us into
          /// escape mode so the escaped character will
          /// be treated as a normal char.
          // added ignore as lint has a bug for conditional in a
          // switch statement #27
          // ignore: invariant_booleans
          if (char == escapeCharacter) {
            stateStack.push(currentState);
            currentState = _ParseFrame(_ParseState.escaped, i);
            break;
          }

          // we just hit a nested quote
          if (char == "'" || char == '"') {
            stateStack.push(currentState);
            currentState = _ParseFrame.forQuote(stateStack, i, char);
          }

          currentWord += char;
          break;

        /// we are in a quote so just suck in
        /// characters until we see a matching quote.
        case _ParseState.nestedQuote:

          // ignore: invariant_booleans
          if (char == currentState.matchingQuote) {
            // We have a matching closing quote
            currentState = stateStack.pop();
            currentWord += char;
            break;
          }

          /// The escape character so put us into
          /// escape mode so the escaped character will
          /// be treated as a normal char.
          // added ignore as lint has a bug for conditional in a
          // switch statement #27
          // ignore: invariant_booleans
          if (char == escapeCharacter) {
            stateStack.push(currentState);
            currentState = _ParseFrame(_ParseState.escaped, i);
            break;
          }

          if (char == "'" || char == '"') {
            // we just hit a nested quote
            stateStack.push(currentState);
            currentState = _ParseFrame.forQuote(stateStack, i, char);
          }
          currentWord += char;
          break;
      }
    }

    if (currentWord.isNotEmpty) {
      parts.add(QArg.fromParsed(currentWord, wasQuoted: false));
    }

    if (parts.isEmpty) {
      throw RunException(
          commandLine, -1, 'The string did not contain a command.');
    }
    cmd = parts[0].arg;

    if (parts.length > 1) {
      return parts.sublist(1);
    } else {
      return <QArg>[];
    }
  }

  ///
  /// to emulate bash and support what most cli apps support we expand
  /// globs.
  /// Any argument that contains *, ? or [ will
  /// be expanded.
  /// See https://github.com/onepub-dev/dcli/issues/56
  ///
  List<String> _expandGlobs(List<QArg> qargs, String? workingDirectory) {
    final expanded = <String>[];

    for (final qarg in qargs) {
      if (qarg.wasQuoted!) {
        expanded.add(qarg.arg);
      } else {
        expanded.addAll(qarg.expandGlob(workingDirectory));
      }
    }
    return expanded;
  }
}

enum _ParseState {
  /// we are between words (on a space or at the begining)
  searching,

  /// we have seen a quote and are looking for the next one.
  inQuote,

  /// The quote is nested within another quote.
  /// there can be multiple levels of nesting
  nestedQuote,

  /// we have seen a non-space character and are collecting
  /// all the pieces that make up the word.
  inWord,

  /// The next character is to be treated litterally
  escaped
}

class _ParseFrame {
  /// Create a [_ParseFrame]
  _ParseFrame(this.state, this.offset);

  /// Create a [_ParseFrame] when we enter the [_ParseState.inQuote] state.
  _ParseFrame.forQuote(
      StackList<_ParseFrame> stack, this.offset, this.matchingQuote)
      : state = isQuoteActive(stack)
            ? _ParseState.nestedQuote
            : _ParseState.inQuote;

  /// The state held by this Frame.
  _ParseState state;

  /// If the state for this [_ParseFrame] is [_ParseState.inQuote]
  /// then this holds the quote character that created the state.
  String? matchingQuote;

  /// The character offset from the start of the command line
  /// that caused us to enter this state.
  int offset;

  @override
  String toString() =>
      '${EnumHelper().getName(state)} offset: $offset quote: $matchingQuote';

  /// Returns true if a quote is already on the stack.
  static bool isQuoteActive(StackList<_ParseFrame> stack) {
    for (final frame in stack.asList()) {
      if (frame.state == _ParseState.inQuote ||
          frame.state == _ParseState.nestedQuote) {
        return true;
      }
    }
    return false;
  }
}

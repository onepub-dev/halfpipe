import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:halfpipe/halfpipe.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('stdin', () async {
    await withEnvironmentAsync(
        environment: {'DOCKER_CONFIG': join(pwd, '.docker')}, () async {
      const password = 'testing';
      var args = '--username onepub';
      return HalfPipe()
          .block((plumber) async {
            /// pass the password via stdin to the docker login command.
            args += ' --password-stdin';
            plumber.sink.add(password);
          })
          .command('docker login $args', terminal: true)
          .exitCode();
    });
  });

  // ignore: unused_element
  Future<void> restore(String sourcePath) async {
    await withEnvironmentAsync(
      environment: {'MYSQL_PWD': 'the password'},
      () async {
        const user = 'some user';
        const host = 'localhost';
        const schema = 'test-schema';
        final size = File(sourcePath).lengthSync();
        if (Terminal().hasTerminal) {
          print('progress: ');
        }
        await HalfPipe()
            .processor(ReadFile(sourcePath))
            // The problem here is that this processer writes to
            // stdout which the next process 'mysql' is reading
            // its dump file from. So there appears to be a bug
            // as the mysql command should be reading from our stream
            // not stdin.
            .processor(ShowProgress(size, (written, total) {
              print('hi');
              if (Terminal().hasTerminal) {
                Terminal().column = 10;
                echo('$written/$total');
              } else {
                print('$written/$total');
              }
            }))
            .command('mysql --user $user --host=$host $schema ')
            .printmix();
        // return ('cat $sourcePath'
        //  | 'mysql --user $user --host=$host $schema ')
        //     .run;
      },
    );
  }
}

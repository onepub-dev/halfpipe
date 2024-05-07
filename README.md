A buider pattern for building processing pipelines that are able to include Dart code and external processes into a single pipeline.

Let's look at an example:

```dart
    final bigWav = File('big.wav');
    /// merge the list of wav's in the current
    /// directory into a single wav
    /// by concatentating them together
    HalfPipe2()
    // run the 'ls' command to get a list of files.
        .command('ls *.wav')) 
        // Convert the output to lines as all calls to command return a List<int>
        .transform(Transform.line) 
        // For each file returned by the 'ls' command, open the file and
        // write the content into the sink.
        .block<List<int>>((srcIn, srcErr, sinkOut, sinkErr) {
            /// listen for the list of filenames
            srcIn.listen((wav) async {
                // open each file and write the content
                // into sinkOut as <int> data
                final ras = await File(wav).openRead();
                sinkOut.addStream(ras.stream);
                ras.close();
            }
            // just pass any errors from the prior phase to the next section in
            // the pipeline
            sinkErr.addStream(srcErr);
        })
        .write(bigWav) // save all the data into bigWav
        .run(); // start the pipeline.
```

# exitCode
When we run an external command it will return an exit code. This exit code can be used to determine if the command was successful or not.

You can obtain the exit code from the command:

```dart

final exitCode = HalfPipe()
   .command('ls', nothrow: true)
   .run()
   .exitCode;
```

Note the use of `nothrow`. If you don't pass the `nothrow` argument then 
HalfPipe will throw an execption if an non-zero exit code is returned.
Without `nothrow: true` the call to `.exitCode` will never execute.

If your pipeline doesn't include a command then exitCode will always return
zero.

If you have multiple commands in your pipeline then the exitCode will be the
exit code of the last command in the pipeline.





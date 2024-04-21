A buider pattern for building processing pipelines that are able to include Dart code and external processes into a single pipeline.

Let's look at an example:

```dart
    final bigWav = File('big.wav');
    /// merge the list of wav's in the current
    /// directory into a single wav
    /// by concatentating them together
    HalfPipe2()
        .command('ls *.wav')) // run the 'ls' command to get a list of files.
        .transform(Transform.line) // Convert the output to lines.
        // Run dart code outputing <int> data.
        .block<int>((srcIn, srcErr, sinkOut, sinkErr) {
            /// listen for the list of filenames
            srcIn.listen((wav) {
                // open each file and write the content
                // into sinkOut as <int> data
                final ras = File(wav).open();
                sinkOut.addStream(ras.stream);
                ras.close();
            }
            // just pass any errors to the next section in
            // the pipeline
            sinkErr.addStream(srcErr);
        })
        .write(bigWav) // save all the data into bigWav
        .run(); // start the pipeline.
```

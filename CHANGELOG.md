# 1.0.3
- upgraded dcli dependencies.

# 1.0.2
- Upgraded to lastet version of dcli.

# 1.0.1
- Upgraded to lastet version of dcli.

# 0.0.2
- Upgraded to lastet version of dcli.

# 0.0.1
- Create LICENSE
- all tests now working.
- fixed bug in readfile. It wasn't reading the errController sink incorrectly and failed to cancel the read subscription.
- formatting.
- Fixed the process pipe line. It wasn't wiring in the underlying processor class streams. I've shorted cut the pipeline as we had an unncessary set of controllers in the processor.
- added an additional check to stream controller ex so we can now report the stream name if a user tries add to the stream when the controller is closed.
- spelling.
- Added additional logging.
- renamed waitUtilComplete to waitUntilOutputDone as it is more evocative.
- working on directory_list
- fixed a bug in the pipe sections that was trying to complete when the section streams had already been completed due to the onError handler already completing. onDone still gets called even when an error occurs.
- corrected the name of the Processor member.
- Merge branch 'master' of github.com:onepub-dev/halfpipe
- add test for stderr.
- Added unit test to use stdout.
- Added logic to close the controllers so that any streams taken from them will shutdown. Fixed a bug with calls to .stdout.
- improved doco.
- corrected return type of comandAndArgs in PipePhase
- corrected return type of start.
- corrected the return type of commandAndArgs
- removed the tee test for the moment.
- lint fixes.
- Merge branch 'master' of https://github.com/onepub-dev/halfpipe
- renamed write to writeToFile Fixed the writeToFile unit test as it wasn't calling a terminal function and added additional tests.
- fixed lints.
- exported additional processors.
- upgraded to dcli 4.x
- fixed unit terts for non-zero exit code.
- expanded unit tests. and improvements to the test_app and calling it.
- doco.
- added logic to correctly throw on non-zero exit code when nothrow is false.
- made the process object private. Added error for invalid app when running under windows.
- starting flesh out unit tests. Added tests for obtaining the exit code for a command.
- improved the doco.
- changed the printxxx methods so that the Err stream is written to stderr.
- introduced the concept of a capture as a terminal function which can return capture output and the exitCode if the last command in the pipeline.
- add captureModeo to the toParagraph method.
- added additinal methods for outputing to a list such as head, tail and toLists which returns err and out as separate lists.
- added logger to project.
- moved old pipeline unit tests to the half_pipe_test.dart.
- fixed the generics on _changeType.
- removed old code.
- improved the doco.
- fixing the file read unit test as they were attempting to read for a non-existant file.
- Fixed ReadFile as it wasn't actually reading the fil. Added a try block so it completes even if an error is thrown.
- futher work on getting all unit tests to work by correctin issues in the pipe_phase run method. Mainly getting the types to align
- Added a catch block to the command processor so that if a command fails the processor still completes all be it with an error.
- added srcErr to the BlockCallback.
- Added a wrapper for stdin so that we can run multiple pipelines that subscribe to stdin. Normally a second subscription attempt would fail.
- added an exception if the user tries to get stderr or stdout when a command is run with terminal=true.
- Fixed the Tee processor
- fixed the bug where the transformer pipe was not completing. closing a streamcontroller will hang indefinitely if the controller is never listened to.
- wip
- first unit test working again after re-engineering the core pipeline. Feels like we are now on the right path by closing each section as the prior one completes. currently working on getting the block section to shutdown.
- added logic to cleanup pipesections as we shutdown the pipeline.
- Merge branch 'master' of https://github.com/onepub-dev/halfpipe
- Merge branch 'master' of https://github.com/onepub-dev/halfpipe
- add stream_controller_ex for better debugging
- upgraded completer_Ex version.
- changed to returning completers from start to give better debug visiblity.
- removed old code
- wip
- wip
- merge the two test classes into one.
- doco.
- grammar
- wip: improvements to the core pipeline - currently not functional.  The PipeSections now provide the controllers so that they can be correctly typed. The Process pipe section now allows data to be transformed to a new type as it passes through the section.
- re-engineered the engine so that transform can return a single line rather than a list of lines. This also makes each section of the pipe more flexible as it is no longer constrained to return a list. reworked the Transform.line to use chunked decoding for the same reason.
- changed the pipesection so that they run in parallel as we need to process the streams in each stage as the data is generated rather than waiting for all of the data to be generated by one stage before running the next stage.
- fixed incorrect import after renaming half_pipe.dart
- formatting
- updated barrel file to reflect correct export filename.
- removed unused classes.
- deleted old HalfPipe and renamed HalfPipe2 to HalfPipe.  First unit test is now working!!
- wip: looks like streams are wired.
- wip - trying to get the wiring of the sections working so data flows from section to section.
- a rough sketch of how I want the api to look. Compiles but is completely untested.
- wip: HalfPipe2 is where I'm experimenting.
- wip
- wip
- wip
- Merge branch 'master' of https://github.com/bsutton/halfpipe
- experiments.
- Update .gitignore
- Create .gitignore
- Delete .gitignore
- first commit

## 1.0.0

- Initial version.

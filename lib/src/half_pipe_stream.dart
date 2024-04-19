// ignore_for_file: avoid_setters_without_getters, one_member_abstracts

import 'dart:async';

abstract class HalfPipeStream {
  Stream<String> get stdout async* {}
  Stream<String> get stderr async* {}
  Stream<String> get stdmix async* {}

  Stream<List<int>> stdoutAsInt() async* {}
  Stream<List<int>> stderrAsInt() async* {}
  Stream<List<int>> stdmixAsInt() async* {}

  Future<void> print();
  Future<void> printerr();
  Future<void> printmix();
}

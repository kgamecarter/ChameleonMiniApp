import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:chameleon_mini_app/services/crapto1.dart';

final class LibCrapto1Nonce extends Struct {
  @Uint32()
  external int nt;
  @Uint32()
  external int nr;
  @Uint32()
  external int ar;
}

final _crapto1Lib = Platform.isAndroid
    ? DynamicLibrary.open('libCrapto1Native.so')
    : DynamicLibrary.process();
final _libCrapto1MfKey32 = _crapto1Lib.lookupFunction<
    Uint64 Function(Uint32, Uint32, Pointer),
    int Function(int, int, Pointer<LibCrapto1Nonce>)>('MfKey32');
final _libCrapto1MfKey64 = _crapto1Lib.lookupFunction<
    Uint64 Function(Uint32, Uint32, Uint32, Uint32, Uint32),
    int Function(int, int, int, int, int)>('MfKey64');

Future<String?> mfKey32Native(int uid, List<Nonce> nonces) async {
  print('Native mfKey32');
  final key = using((arena) {
    final nativeNonces = arena<LibCrapto1Nonce>(nonces.length);
    for (var i = 0; i < nonces.length; i++) {
      nativeNonces[i].nt = nonces[i].nt;
      nativeNonces[i].nr = nonces[i].nr;
      nativeNonces[i].ar = nonces[i].ar;
    }
    return _libCrapto1MfKey32(uid, nonces.length, nativeNonces);
  });
  return key.toRadixString(16).toUpperCase().padLeft(12, '0');
}

Future<String?> mfKey64Native(int uid, int nt, int nr, int ar, int at) async {
  print('Native mfKey64');
  final key = _libCrapto1MfKey64(uid, nt, nr, ar, at);
  return key.toRadixString(16).toUpperCase().padLeft(12, '0');
}

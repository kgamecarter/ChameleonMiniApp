import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:queries/collections.dart';


const _platform = const MethodChannel('tw.kgame.crapto1/mfkey');

class Crypto1State {
  int odd = 0;
  int even = 0;

  Crypto1State(this.odd, this.even);

  Crypto1State.fromKey(String key) {
    for (var i = 0; i < 6; i++) {
      var b = int.parse(key.substring(i << 1, i + 1 << 1), radix: 16);
      for (var j = 0; j < 4; j++) {
        even = even << 1 | b & 1;
        b >>= 1;
        odd = odd << 1 | b & 1;
        b >>= 1;
      }
    }
  }

  String get lfsr {
    var o = odd, e = even;
    var key = "";
    for (var i = 0; i < 6; i++) {
      var b = 0;
      for (var j = 0; j < 4; j++) {
        b = b << 1 | o & 1;
        o >>= 1;
        b = b << 1 | e & 1;
        e >>= 1;
      }
      key = b.toRadixString(16) + key;
    }
    return key.toUpperCase();
  }
}

class Crypto1 {
  static const int LF_POLY_ODD = 0x29CE5C;
  static const int LF_POLY_EVEN = 0x870804;

  Crypto1State state;

  Crypto1(this.state);

  int crypto1Bit([int _in = 0, bool isEncrypted = false]) {
    int feedin;
    int ret = filter(state.odd);

    feedin = ret & (isEncrypted ? 1 : 0);
    feedin ^= _in != 0 ? 1 : 0;
    feedin ^= LF_POLY_ODD & state.odd;
    feedin ^= LF_POLY_EVEN & state.even;
    state.even = state.even << 1 | evenParity32(feedin);

    int x = state.odd;
    state.odd = state.even;
    state.even = x;
    
    return ret;
  }
  
  int crypto1int([int _in = 0, bool isEncrypted = false]) {
    int ret = 0;
    for (var i = 0; i < 8; ++i)
      ret |= crypto1Bit(_bit(_in, i), isEncrypted) << i;
    return ret;
  }

  int crypto1Word([int _in = 0, bool isEncrypted = false]) {
    int ret = 0;
    for (var i = 0; i < 32; ++i)
      ret |= crypto1Bit(_beBit(_in, i), isEncrypted) << (i ^ 24);
    return ret;
  }

  int peekCrypto1Bit() => filter(state.odd);
}

int _bit(int v, int n) => v >> n & 1;

int _beBit(int v, int n) => _bit(v, n ^ 24);

int filter(int x) {
  int f;
  f = 0xf22c0 >> (x & 0xf) & 16;
  f |= 0x6c9c0 >> (x >> 4 & 0xf) & 8;
  f |= 0x3c8b0 >> (x >> 8 & 0xf) & 4;
  f |= 0x1e458 >> (x >> 12 & 0xf) & 2;
  f |= 0x0d938 >> (x >> 16 & 0xf) & 1;
  return 0xEC57E80A >> f & 1;
}

const List<int> _oddintParity = <int>[
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1
];

int oddParity8(int x) => _oddintParity[x & 0xFF];

int evenParity8(int x) => _oddintParity[x & 0xFF] ^ 1;

int evenParity32(int x) {
  x ^= x >> 16;
  x ^= x >> 8;
  return evenParity8(x);
}

int swapEndian(int x) {
  x = (x >> 8 & 0xff00ff) | (x & 0xff00ff) << 8;
  x &= 0xFFFFFFFF;
  x = x >> 16 | x << 16;
  x &= 0xFFFFFFFF;
  return x;
}

int prngSuccessor(int x, int n) {
    x = swapEndian(x);
    while (n-- > 0)
      x = x >> 1 | ((x >> 16 ^ x >> 18 ^ x >> 19 ^ x >> 21) & 1) << 31;
    return swapEndian(x);
}

class Span {
  Uint32List list;
  int offset;
  late int length;

  Span(this.list, [this.offset = 0, int? length]) {
    if (length == null)
      this.length = list.length - offset;
    else
      this.length = length;
  }

  Span slice(int start, [int? len]) {
    return Span(list, offset + start, len != null ? len : length - start);
  }

  void sort() {
    var sublist = list.sublist(offset, length + offset);
    sublist.sort();
    for (int i = 0; i < length; i++)
      this[i] = sublist[i];
  }

  int binarySearch() {
    int start = 0, stop = this.length - 1, mid;
    int val = this[stop] & 0xff000000;
    while (start != stop)
      if (this[start + (mid = (stop - start) >> 1)] > val)
        stop = start + mid;
      else
        start += mid + 1;
    return start;
  }

  operator [](int i) => list[i + offset];
  operator []=(int i, int value) => list[i + offset] = value;
}

class Crapto1 extends Crypto1
{
  Crapto1(Crypto1State state) : super(state);

  int lfsrRollbackBit([int _in = 0, bool isEncrypted = false]) {
    int _out;
    int ret;

    state.odd &= 0xffffff;
    var t = state.odd;
    state.odd = state.even;
    state.even = t;

    _out = state.even & 1;
    _out ^= Crypto1.LF_POLY_EVEN & (state.even >>= 1);
    _out ^= Crypto1.LF_POLY_ODD & state.odd;
    _out ^= _in != 0 ? 1 : 0;
    _out ^= (ret = filter(state.odd)) & (isEncrypted ? 1 : 0);

    state.even |= evenParity32(_out) << 23;
    return ret;
  }

  int lfsrRollbackint([int _in = 0, bool isEncrypted = false]) {
    int ret = 0;
    for (var i = 7; i >= 0; --i)
      ret |= lfsrRollbackBit(_bit(_in, i), isEncrypted) << i;
    return ret;
  }

  int lfsrRollbackWord([int _in = 0, bool isEncrypted = false]) {
    int ret = 0;
    for (var i = 31; i >= 0; --i)
      ret |= lfsrRollbackBit(_beBit(_in, i), isEncrypted) << (i ^ 24);
    return ret;
  }

  static int _updateContribution(int item, int mask1, int mask2) {
    int p = item >> 25;
    p = p << 1 | evenParity32(item & mask1);
    p = p << 1 | evenParity32(item & mask2);
    item = p << 24 | (item & 0xffffff);
    return item & 0xFFFFFFFF;
  }

  static int _extendTable(Span tbl, int end, int bit, int m1, int m2, int _in) {
    _in <<= 24;
    var i = 0;
    for (tbl[i] <<= 1; i <= end; tbl[++i] <<= 1)
      if ((filter(tbl[i]) ^ filter(tbl[i] | 1)) != 0) {
        tbl[i] |= filter(tbl[i]) ^ bit;
        tbl[i] = _updateContribution(tbl[i], m1, m2);
        tbl[i] ^= _in;
      } else if (filter(tbl[i]) == bit) {
        tbl[++end] = tbl[i + 1];
        tbl[i + 1] = tbl[i] | 1;
        tbl[i] = _updateContribution(tbl[i], m1, m2);
        tbl[i++] ^= _in;
        tbl[i] = _updateContribution(tbl[i], m1, m2);
        tbl[i] ^= _in;
      } else
        tbl[i--] = tbl[end--];
    return end;
  }

  static int _extendTableSimple(Uint32List tbl, int end, int bit) {
    var i = 0;
    for (tbl[i] <<= 1; i <= end; tbl[++i] <<= 1) {
      if ((filter(tbl[i]) ^ filter(tbl[i] | 1)) != 0) {
        tbl[i] |= filter(tbl[i]) ^ bit;
      } else if (filter(tbl[i]) == bit) {
        tbl[++end] = tbl[++i];
        tbl[i] = tbl[i - 1] | 1;
      } else {
        tbl[i--] = tbl[end--];
      }
    }
    return end;
  }

  static void _recover(Span odd, int oddTail, int oks, Span even, int evenTail, int eks, int rem, List<Crypto1State> sl, int _in) {
    var o = 0;
    var e = 0;

    if (rem == -1) {
      for (e = 0; e <= evenTail; e++) {
        even[e] = even[e] << 1 ^ evenParity32(even[e] & Crypto1.LF_POLY_EVEN) ^ ((_in & 4) != 0 ? 1 : 0);
        for (o = 0; o <= oddTail; o++) {
          sl.add(
            Crypto1State(
              even[e] ^ evenParity32(odd[o] & Crypto1.LF_POLY_ODD),
              odd[o],
            )
          );
        }
      }
      return;
    }

    for (var i = 0; i < 4 && rem-- != 0; i++) {
      oks >>= 1;
      eks >>= 1;
      _in >>= 2;
      oddTail = _extendTable(odd, oddTail, oks & 1, Crypto1.LF_POLY_EVEN << 1 | 1, Crypto1.LF_POLY_ODD << 1, 0);
      if (0 > oddTail)
        return;

      evenTail = _extendTable(even, evenTail, eks & 1, Crypto1.LF_POLY_ODD, Crypto1.LF_POLY_EVEN << 1 | 1, _in & 3);
      if (0 > evenTail)
        return;
    }

    odd.slice(0, oddTail + 1).sort();
    even.slice(0, evenTail + 1).sort();

    while (oddTail >= 0 && evenTail >= 0)
      if (((odd[oddTail] ^ even[evenTail]) >> 24) == 0) {
        oddTail = odd.slice(0, (o = oddTail) + 1).binarySearch();
        evenTail = even.slice(0, (e = evenTail) + 1).binarySearch();
        _recover(odd.slice(oddTail), o - oddTail, oks, even.slice(evenTail), e - evenTail, eks, rem, sl, _in);
        oddTail--; evenTail--;
      }
      else if (odd[oddTail] > even[evenTail])
        oddTail = odd.slice(0, oddTail + 1).binarySearch() - 1;
      else
        evenTail = even.slice(0, evenTail + 1).binarySearch() - 1;
  }

  static List<Crypto1State> lfsrRecovery32(int ks2, int _in) {
    var oks = 0;
    var eks = 0;

    for (var i = 31; i >= 0; i -= 2)
      oks = oks << 1 | _beBit(ks2, i);
    for (var i = 30; i >= 0; i -= 2)
      eks = eks << 1 | _beBit(ks2, i);

    var odd = Uint32List(4 << 21);
    var even = Uint32List(4 << 21);
    List<Crypto1State> statelist = [];
    var oddTail = 0;
    var evenTail = 0;

    for (var i = 1 << 20; i >= 0; --i) {
      if (filter(i) == (oks & 1))
        odd[++oddTail] = i;
      if (filter(i) == (eks & 1))
        even[++evenTail] = i;
    }

    for (var i = 0; i < 4; i++) {
      oddTail = _extendTableSimple(odd, oddTail, (oks >>= 1) & 1);
      evenTail = _extendTableSimple(even, evenTail, (eks >>= 1) & 1);
    }

    _in = (_in >> 16 & 0xff) | (_in << 16) | (_in & 0xff00);
    _recover(Span(odd), oddTail, oks, Span(even), evenTail, eks, 11, statelist, _in << 1);

    return statelist;
  }

  
  static const List<int> _S1 = const <int>[
    0x62141, 0x310A0, 0x18850, 0x0C428, 0x06214, 0x0310A,
    0x85E30, 0xC69AD, 0x634D6, 0xB5CDE, 0xDE8DA, 0x6F46D,
    0xB3C83, 0x59E41, 0xA8995,  0xD027F, 0x6813F, 0x3409F, 0x9E6FA ];

  static const List<int> _S2 = const <int>[
    0x3A557B00, 0x5D2ABD80, 0x2E955EC0, 0x174AAF60, 0x0BA557B0,
    0x05D2ABD8, 0x0449DE68, 0x048464B0, 0x42423258, 0x278192A8,
    0x156042D0, 0x0AB02168, 0x43F89B30, 0x61FC4D98, 0x765EAD48,
    0x7D8FDD20, 0x7EC7EE90, 0x7F63F748, 0x79117020 ];
  static const List<int> _T1 = const <int>[
    0x4F37D, 0x279BE, 0x97A6A, 0x4BD35, 0x25E9A, 0x12F4D, 0x097A6, 0x80D66,
    0xC4006, 0x62003, 0xB56B4, 0x5AB5A, 0xA9318, 0xD0F39, 0x6879C, 0xB057B,
    0x582BD, 0x2C15E, 0x160AF, 0x8F6E2, 0xC3DC4, 0xE5857, 0x72C2B, 0x39615,
    0x98DBF, 0xC806A, 0xE0680, 0x70340, 0x381A0, 0x98665, 0x4C332, 0xA272C ];
  static const List<int> _T2 = const <int>[
    0x3C88B810, 0x5E445C08, 0x2982A580, 0x14C152C0, 0x4A60A960,
    0x253054B0, 0x52982A58, 0x2FEC9EA8, 0x1156C4D0, 0x08AB6268,
    0x42F53AB0, 0x217A9D58, 0x161DC528, 0x0DAE6910, 0x46D73488,
    0x25CB11C0, 0x52E588E0, 0x6972C470, 0x34B96238, 0x5CFC3A98,
    0x28DE96C8, 0x12CFC0E0, 0x4967E070, 0x64B3F038, 0x74F97398,
    0x7CDC3248, 0x38CE92A0, 0x1C674950, 0x0E33A4A8, 0x01B959D0,
    0x40DCACE8, 0x26CEDDF0 ];

  static const List<int> _C1 = const <int>[ 0x846B5, 0x4235A, 0x211AD ];
  static const List<int> _C2 = const <int>[ 0x1A822E0, 0x21A822E0, 0x21A822E0 ];

  static List<Crypto1State> lfsrRecovery64(int ks2, int ks3) {
    var oks = Uint8List(32);
    var eks = Uint8List(32);
    var hi = Uint8List(32);
    var low = 0;
    var win = 0;
    var table = Uint32List(1 << 16);
    List<Crypto1State> statelist = [];

    for (var i = 30; i >= 0; i -= 2) {
      oks[i >> 1] = _beBit(ks2, i);
      oks[16 + (i >> 1)] = _beBit(ks3, i);
    }
    for (var i = 31; i >= 0; i -= 2) {
      eks[i >> 1] = _beBit(ks2, i);
      eks[16 + (i >> 1)] = _beBit(ks3, i);
    }


    for (var i = 0xfffff; i >= 0; i--) {
      if (filter(i) != oks[0])
        continue;

      var tail = 0;
      table[tail] = i;

      for (var j = 1; tail >= 0 && j < 29; j++)
        tail = _extendTableSimple(table, tail, oks[j]);
      if (tail < 0)
        continue;

      for (var j = 0; j < 19; ++j)
        low = low << 1 | evenParity32(i & _S1[j]);
      for (var j = 0; j < 32; ++j)
        hi[j] = evenParity32(i & _T1[j]);


      for (; tail >= 0; --tail) {
        bool continue2 = false;
        for (var j = 0; j < 3; j++) {
          table[tail] = table[tail] << 1;
          table[tail] |= evenParity32((i & _C1[j]) ^ (table[tail] & _C2[j]));
          if (filter(table[tail]) != oks[29 + j]) {
            continue2 = true;
            break;
          }
        }
        if (continue2) continue;

        for (var j = 0; j < 19; j++)
          win = win << 1 | evenParity32(table[tail] & _S2[j]);

        win ^= low;
        for (var j = 0; j < 32; ++j) {
          win = win << 1 ^ hi[j] ^ evenParity32(table[tail] & _T2[j]);
          if (filter(win) != eks[j]) {
            continue2 = true;
            break;
          }
        }
        if (continue2) continue;

        table[tail] = table[tail] << 1 | evenParity32(Crypto1.LF_POLY_EVEN & table[tail]);
        statelist.add(
          Crypto1State(
            table[tail] ^ evenParity32(Crypto1.LF_POLY_ODD & win),
            win
          )
        );
      }
    }
    return statelist;
  }
}

class Nonce {
  int sector = 0, block = 0, type = 0;
  int nt = 0;
  int nr = 0;
  int ar = 0;

  Nonce();
  
  Nonce.fromJson(Map<String, dynamic> json)
    : sector = json['sector'],
      block = json['block'],
      type = json['type'],
      nt = json['nt'],
      nr = json['nr'],
      ar = json['ar'];

  Map<String, dynamic> toJson() => <String, dynamic>{      
    'sector': this.sector,
    'block': this.block,
    'type': this.type,
    'nt': this.nt,
    'nr': this.nr,
    'ar': this.ar,
  };
}

Future<String> mfKey32(int uid, Iterable<Nonce> nonces) {
  print('Dart mfKey32');
  print('UID: ${uid.toRadixString(16)}');
  print('Nonces: ${jsonEncode(nonces)}');
  var nonce = nonces.first;
  nonces = nonces.skip(1).toList();
  var p640 = prngSuccessor(nonce.nt, 64);
  print(p640.toRadixString(16));
  var list = Crapto1.lfsrRecovery32(nonce.ar ^ p640, 0);
  print(list.length);
  List<String> keys = [];
  var crapto1 = Crapto1(Crypto1State(0, 0));
  var crypto1 = Crypto1(Crypto1State(0, 0));
  for (var s in list) {
    crapto1.state = s;
    crapto1.lfsrRollbackWord();
    crapto1.lfsrRollbackWord(nonce.nr, true);
    crapto1.lfsrRollbackWord(uid ^ nonce.nt);
    var allPass = true;
    for (var n in nonces) {
      crypto1.state.odd = s.odd;
      crypto1.state.even = s.even;
      crypto1.crypto1Word(uid ^ n.nt);
      crypto1.crypto1Word(n.nr, true);
      var p641 = prngSuccessor(n.nt, 64);
      if (n.ar != (crypto1.crypto1Word() ^ p641)) {
        allPass = false;
        break;
      }
    }
    if (allPass)
      keys.add(s.lfsr);
  }
  return Future<String>.value(keys.length == 1 ? keys[0] : null);
}

String mfKey64(int uid, int nt, int nr, int ar, int at) {
  // Extract the keystream from the messages
  var ks2 = ar ^ prngSuccessor(nt, 64); // keystream used to encrypt reader response
  var ks3 = at ^ prngSuccessor(nt, 96); // keystream used to encrypt tag response
  var revstate = Crapto1.lfsrRecovery64(ks2, ks3)[0];
  var crapto1 = Crapto1(revstate);
  crapto1.lfsrRollbackWord();
  crapto1.lfsrRollbackWord();
  crapto1.lfsrRollbackWord(nr, true);
  crapto1.lfsrRollbackWord(uid ^ nt);
  return crapto1.state.lfsr;
}

typedef Future<String?> MfKey32Function(int uid, List<Nonce> nonces);

class KeyWorkMessage {
  MfKey32Function mfkey32;
  int uid;
  Collection<Nonce> nonces;

  KeyWorkMessage(this.mfkey32, this.uid, this.nonces);
}

Future<List<String>> keyWork(KeyWorkMessage msg) async {  
  List<List<Nonce>?> list = msg.nonces
    .groupBy((n) => 'Sec${n.sector} Key${n.type == 0x60 ? 'A': 'B'}')
    .select((g) {
      var ns = g.toList();
      if (ns.length < 2)
        return null;
      return ns;
    }).where((List<Nonce>? v) => v != null)
    .toList();
  var s = Stopwatch();
  s.start();
  List<String> r = [];
  var fs = list
    .map((List<Nonce>? ns) => msg.mfkey32(msg.uid, ns!))
    .toList();
  var keys = await Future.wait(fs);
  s.stop();
  print('${s.elapsedMilliseconds}ms');
  for (var i = 0; i < list.length; i++) {
    if (keys[i] == null)
      continue;
    var ns = list[i]!;
    r.add('Sec${ns[0].sector} Key${ns[0].type == 0x60 ? 'A': 'B'} ${keys[i]}');
  }
  return r;
}

bool _init = false;
Map<int, Completer<String>> _tasks = Map<int, Completer<String>>();
Future<String> mfKey32Java(int uid, List<Nonce> nonces) async {
  print('Java mfKey32');
  print('UID: ${uid.toRadixString(16)}');
  print('Nonces: ${jsonEncode(nonces)}');
  if (!_init) {
    _init = true;
    _platform.setMethodCallHandler((call) async {
      int id = call.arguments['id'];
      int? key = call.arguments['key'];
      final completer = _tasks.remove(id);
      completer?.complete(key?.toRadixString(16).toUpperCase().padLeft(12, '0'));
    });
  }
  var map = Map<String, dynamic>();
  map['uid'] = uid;
  map['nonces'] = nonces.map<Map<String, int>>((n) {
    var map = Map<String, int>();
    map['nt'] = n.nt;
    map['nr'] = n.nr;
    map['ar'] = n.ar;
    return map;
  }).toList();
  int id = await _platform.invokeMethod('mfkey32', map);
  var completer = Completer<String>();
  _tasks[id] = completer;
  return completer.future;
}

Future<String?> mfKey32Online(int uid, List<Nonce> nonces) async {
  print('Online mfKey32');
  print('UID: ${uid.toRadixString(16)}');
  var json = jsonEncode(nonces);
  print('Nonces: $json');
  final response = await http.post('https://mfkeyonline.azurewebsites.net/Mfkey32?uid=$uid',
    headers: {"Content-Type": "application/json"},
    body: json,);
  if (response.statusCode == 200) {
    int key = int.parse(response.body);
    if (key == -1)
      return null;
    return key.toRadixString(16).toUpperCase().padLeft(12, '0');
  } else {
    throw Exception('Failed to post');
  }
}
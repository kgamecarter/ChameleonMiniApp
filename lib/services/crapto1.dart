class Crypto1State {
  int odd = 0;
  int even = 0;

  Crypto1State();

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

  Crypto1([this.state]);

  int crypto1Bit([int _in = 0, bool isEncrypted = false])
  {
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
  
  int crypto1Byte([int _in = 0, bool isEncrypted = false])
  {
    int ret = 0;
    for (var i = 0; i < 8; ++i)
      ret |= crypto1Bit(_bit(_in, i), isEncrypted) << i;
    return ret;
  }

  int crypto1Word([int _in = 0, bool isEncrypted = false])
  {
    int ret = 0;
    for (var i = 0; i < 32; ++i)
      ret |= crypto1Bit(_beBit(_in, i), isEncrypted) << (i ^ 24);
    return ret;
  }

  int peekCrypto1Bit() => filter(state.odd);

  int _bit(int v, int n) => v >> n & 1;

  int _beBit(int v, int n) => _bit(v, n ^ 24);
}

int filter(int x)
{
  int f;
  f = 0xf22c0 >> (x & 0xf) & 16;
  f |= 0x6c9c0 >> (x >> 4 & 0xf) & 8;
  f |= 0x3c8b0 >> (x >> 8 & 0xf) & 4;
  f |= 0x1e458 >> (x >> 12 & 0xf) & 2;
  f |= 0x0d938 >> (x >> 16 & 0xf) & 1;
  return 0xEC57E80A >> f & 1;
}

const List<int> _oddByteParity = <int>[
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

int oddParity8(int x) => _oddByteParity[x];

int evenParity8(int x) => _oddByteParity[x] ^ 1;

int evenParity32(int x)
{
  x ^= x >> 16;
  x ^= x >> 8;
  return evenParity8(x);
}

int swapEndian(int x)
{
  x = (x >> 8 & 0xff00ff) | (x & 0xff00ff) << 8;
  x = x >> 16 | x << 16;
  return x;
}

int prngSuccessor(int x, int n)
{
    x = swapEndian(x);
    while (n-- > 0)
      x = x >> 1 | (x >> 16 ^ x >> 18 ^ x >> 19 ^ x >> 21) << 31;
    return swapEndian(x);
}
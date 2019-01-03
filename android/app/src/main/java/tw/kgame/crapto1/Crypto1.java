package tw.kgame.crapto1;

public class Crypto1 {
    public final int LF_POLY_ODD = 0x29CE5C;
    public final int LF_POLY_EVEN = 0x870804;

    public Crypto1State state;

    byte bit(long v, int n) {
        return (byte)(v >> n & 1);
    }

    byte beBit(long v, int n) {
        return bit(v, n ^ 24);
    }

    public byte crypto1Bit(byte _in, boolean isEncrypted) {
        byte ret = filter(state.odd);

        int feedin = ret & (isEncrypted ? 1 : 0);
        feedin ^= _in != 0 ? 1 : 0;
        feedin ^= LF_POLY_ODD & state.odd;
        feedin ^= LF_POLY_EVEN & state.even;
        state.even = state.even << 1 | evenParity32(feedin);

        int x = state.odd;
        state.odd = state.even;
        state.even = x;

        return ret;
    }

    public byte crypto1Byte(byte _in, boolean isEncrypted) {
        byte ret = 0;

        for (int i = 0; i < 8; ++i)
            ret |= (byte)(crypto1Bit(bit(_in, i), isEncrypted) << i);

        return ret;
    }

    public int crypto1Word(int _in, boolean isEncrypted) {
        int ret = 0;

        for (int i = 0; i < 32; ++i)
            ret |= (int)crypto1Bit(beBit(_in, i), isEncrypted) << (i ^ 24);

        return ret;
    }

    byte filter(int x) {
        int f;
        f = 0xf22c0 >> (x & 0xf) & 16;
        f |= 0x6c9c0 >> (x >> 4 & 0xf) & 8;
        f |= 0x3c8b0 >> (x >> 8 & 0xf) & 4;
        f |= 0x1e458 >> (x >> 12 & 0xf) & 2;
        f |= 0x0d938 >> (x >> 16 & 0xf) & 1;
        return (byte)(0xEC57E80A >> f & 1);
    }

     byte[] _oddintParity = new byte[] {
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
     };

    byte oddParity8(byte x) { return _oddintParity[x]; }

    byte evenParity8(byte x) { return (byte)(_oddintParity[x] ^ 1); }

    byte evenParity32(int x) {
        x ^= x >> 16;
        x ^= x >> 8;
        return evenParity8((byte)x);
    }
}
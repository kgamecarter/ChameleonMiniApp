package tw.kgame.crapto1;

public class Crypto1 {
    public static final long LF_POLY_ODD = 0x29CE5CL;
    public static final long LF_POLY_EVEN = 0x870804L;

    public Crypto1State state;

    public Crypto1() { }

    public Crypto1(Crypto1State state) { this.state = state; }

    static byte bit(long v, int n) {
        return (byte)(v >> n & 1);
    }

    static byte beBit(long v, int n) {
        return bit(v, n ^ 24);
    }

    public byte crypto1Bit(byte _in, boolean isEncrypted) {
        byte ret = filter(state.odd);

        long feedin = ret & (isEncrypted ? 1 : 0);
        feedin ^= _in != 0 ? 1 : 0;
        feedin ^= LF_POLY_ODD & state.odd;
        feedin ^= LF_POLY_EVEN & state.even;
        state.even = state.even << 1 | evenParity32(feedin);

        long x = state.odd;
        state.odd = state.even;
        state.even = x;

        return ret;
    }

    public short crypto1Byte(short _in, boolean isEncrypted) {
        short ret = 0;

        for (int i = 0; i < 8; ++i)
            ret |= (short)(crypto1Bit(bit(_in, i), isEncrypted) << i);

        return (short)(ret & 0xFF);
    }

    public long crypto1Word(long _in, boolean isEncrypted) {
        long ret = 0;

        for (int i = 0; i < 32; ++i)
            ret |= (long)crypto1Bit(beBit(_in, i), isEncrypted) << (i ^ 24);

        return ret & 0xFFFFFFFFL;
    }

    protected static byte filter(long x) {
        long f;
        f = 0xf22c0 >> (x & 0xf) & 16;
        f |= 0x6c9c0 >> (x >> 4 & 0xf) & 8;
        f |= 0x3c8b0 >> (x >> 8 & 0xf) & 4;
        f |= 0x1e458 >> (x >> 12 & 0xf) & 2;
        f |= 0x0d938 >> (x >> 16 & 0xf) & 1;
        return (byte)(0xEC57E80A >> f & 1);
    }

    static byte[] _oddintParity = new byte[] {
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

    protected static byte oddParity8(short x) { return _oddintParity[x & 0xFF]; }

    protected static byte evenParity8(short x) { return (byte)(_oddintParity[x & 0xFF] ^ 1); }

    protected static byte evenParity32(long x) {
        x ^= x >> 16;
        x ^= x >> 8;
        return evenParity8((short)(x & 0xFF));
    }
}
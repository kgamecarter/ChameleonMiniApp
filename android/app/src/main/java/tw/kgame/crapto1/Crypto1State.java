package tw.kgame.crapto1;

public class Crypto1State {
    public int odd;
    public int even;

    byte bit(long v, int n) {
        return (byte)(v >> n & 1);
    }

    byte beBit(long v, int n) {
        return bit(v, n ^ 24);
    }

    public Crypto1State(int odd, int even) {
        this.odd = odd;
        this.even = even;
    }

    public Crypto1State(long key) {
        for (int i = 47; i > 0; i -= 2)
        {
            odd = odd << 1 | bit(key, (i - 1) ^ 7);
            even = even << 1 | bit(key, i ^ 7);
        }
    }

    public long getLfsr() {
        long lfsr = 0;
        for (int i = 23; i >= 0; --i)
        {
            lfsr = lfsr << 1 | bit(odd, i ^ 3);
            lfsr = lfsr << 1 | bit(even, i ^ 3);
        }
        return lfsr;
    }
}
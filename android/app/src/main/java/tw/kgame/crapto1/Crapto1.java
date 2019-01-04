package tw.kgame.crapto1;

public class Crapto1 extends Crypto1 {
    public Crapto1() { }

    public Crapto1(Crypto1State state)  { super(state); }
    
    public byte lfsrRollbackBit(byte _in, boolean isEncrypted)
    {
        int _out;
        byte ret;

        state.odd &= 0xffffff;
        int t = state.odd;
        state.odd = state.even;
        state.even = t;

        _out = state.even & 1;
        _out ^= LF_POLY_EVEN & (state.even >>= 1);
        _out ^= LF_POLY_ODD & state.odd;
        _out ^= _in != 0 ? 1 : 0;
        _out ^= (ret = filter(state.odd)) & (isEncrypted ? 1 : 0);

        state.even |= (int)evenParity32(_out) << 23;
        return ret;
    }

    public byte lfsrRollbackByte(byte _in, boolean isEncrypted)
    {
        byte ret = 0;
        for (int i = 7; i >= 0; --i)
            ret |= (byte)(lfsrRollbackBit(bit(_in, i), isEncrypted) << i);
        return ret;
    }

    public int lfsrRollbackWord(int _in, boolean isEncrypted)
    {
        int ret = 0;
        for (int i = 31; i >= 0; --i)
            ret |= (int)lfsrRollbackBit(beBit(_in, i), isEncrypted) << (i ^ 24);
        return ret;
    }
}

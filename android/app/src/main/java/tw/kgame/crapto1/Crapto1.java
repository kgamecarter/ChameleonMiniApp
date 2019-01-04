package tw.kgame.crapto1;

import java.util.*;

public class Crapto1 extends Crypto1 {
    public Crapto1() { }

    public Crapto1(Crypto1State state)  { super(state); }
    
    public byte lfsrRollbackBit(byte _in, boolean isEncrypted)
    {
        long _out;
        byte ret;

        state.odd &= 0xffffff;
        long t = state.odd;
        state.odd = state.even;
        state.even = t;

        _out = state.even & 1;
        _out ^= LF_POLY_EVEN & (state.even >>= 1);
        _out ^= LF_POLY_ODD & state.odd;
        _out ^= _in != 0 ? 1 : 0;
        _out ^= (ret = filter(state.odd)) & (isEncrypted ? 1 : 0);

        state.even |= (long)evenParity32(_out) << 23;
        return ret;
    }

    public short lfsrRollbackByte(short _in, boolean isEncrypted)
    {
        short ret = 0;
        for (int i = 7; i >= 0; --i)
            ret |= (short)(lfsrRollbackBit(bit(_in, i), isEncrypted) << i);
        return (short)(ret & 0xFF);
    }

    public long lfsrRollbackWord(long _in, boolean isEncrypted)
    {
        long ret = 0;
        for (int i = 31; i >= 0; --i)
            ret |= (long)lfsrRollbackBit(beBit(_in, i), isEncrypted) << (i ^ 24);
        return ret;
    }

    private static long updateContribution(long item, long mask1, long mask2)
    {
        long p = item >> 25;
        p = p << 1 | evenParity32(item & mask1);
        p = p << 1 | evenParity32(item & mask2);
        item = p << 24 | (item & 0xffffff);
        return item & 0xFFFFFFFFL;
    }
    
    static int extendTable(Span tbl, int end, long bit, long m1, long m2, long _in) {
        _in <<= 24;
        int i = 0;
        for (tbl.set(i, tbl.get(i) << 1); i <= end; ++i, tbl.set(i, tbl.get(i) << 1))
            if ((filter(tbl.get(i)) ^ filter(tbl.get(i) | 1)) != 0)
            {
                tbl.set(i, tbl.get(i) | (filter(tbl.get(i)) ^ bit));
                tbl.set(i, updateContribution(tbl.get(i), m1, m2));
                tbl.set(i, tbl.get(i) ^ _in);
            }
            else if (filter(tbl.get(i)) == bit)
            {
                tbl.set(++end, tbl.get(i + 1));
                tbl.set(i + 1, tbl.get(i) | 1);
                tbl.set(i, updateContribution(tbl.get(i), m1, m2));
                tbl.set(i, tbl.get(i) ^ _in);
                i++;
                tbl.set(i, updateContribution(tbl.get(i), m1, m2));
                tbl.set(i, tbl.get(i) ^ _in);
            }
            else
                tbl.set(i--, tbl.get(end--));
        return end;
    }

    static int extendTableSimple(long[] tbl, int end, long bit)
    {
        int i = 0;
        for (tbl[i] <<= 1; i <= end; tbl[++i] <<= 1)
        {
            if ((filter(tbl[i]) ^ filter(tbl[i] | 1)) != 0)
            {
                tbl[i] |= filter(tbl[i]) ^ bit;
            }
            else if (filter(tbl[i]) == bit)
            {
                tbl[++end] = tbl[++i];
                tbl[i] = tbl[i - 1] | 1;
            }
            else
            {
                tbl[i--] = tbl[end--];
            }
        }
        return end;
    }

    static void recover(Span odd, int oddTail, long oks, Span even, int evenTail, long eks, int rem, List<Crypto1State> sl, long _in)
    {
        int o = 0;
        int e = 0;

        if (rem == -1)
        {
            for (e = 0; e <= evenTail; e++)
            {
                even.set(e, even.get(e) << 1 ^ evenParity32(even.get(e) & Crypto1.LF_POLY_EVEN) ^ ((_in & 4) != 0 ? 1 : 0));
                for (o = 0; o <= oddTail; o++)
                {
                    sl.add(new Crypto1State(even.get(e) ^ evenParity32(odd.get(o) & Crypto1.LF_POLY_ODD), odd.get(o)));
                }
            }
            return ;
        }

        for (int i = 0; i < 4 && rem-- != 0; i++)
        {
            oks >>= 1;
            eks >>= 1;
            _in >>= 2;
            oddTail = extendTable(odd, oddTail, oks & 1, Crypto1.LF_POLY_EVEN << 1 | 1, Crypto1.LF_POLY_ODD << 1, 0);
            if (0 > oddTail)
                return;

            evenTail = extendTable(even, evenTail, eks & 1, Crypto1.LF_POLY_ODD, Crypto1.LF_POLY_EVEN << 1 | 1, _in & 3);
            if (0 > evenTail)
                return;
        }

        odd.slice(0, oddTail + 1).sort();
        even.slice(0, evenTail + 1).sort();

        while (oddTail >= 0 && evenTail >= 0)
            if (((odd.get(oddTail) ^ even.get(evenTail)) >> 24) == 0)
            {
                oddTail = odd.slice(0, (o = oddTail) + 1).binarySearch();
                evenTail = even.slice(0, (e = evenTail) + 1).binarySearch();
                recover(odd.slice(oddTail), o - oddTail, oks, even.slice(evenTail), e - evenTail, eks, rem, sl, _in);
                oddTail--; evenTail--;
            }
            else if (odd.get(oddTail) > even.get(evenTail))
                oddTail = odd.slice(0, oddTail + 1).binarySearch() - 1;
            else
                evenTail = even.slice(0, evenTail + 1).binarySearch() - 1;
    }

    public static List<Crypto1State> lfsrRecovery32(long ks2, long _in)
    {
        long oks = 0;
        long eks = 0;

        for (int i = 31; i >= 0; i -= 2)
            oks = oks << 1 | beBit(ks2, i);
        for (int i = 30; i >= 0; i -= 2)
            eks = eks << 1 | beBit(ks2, i);

        long[] odd = new long[4 << 21];
        long[] even = new long[4 << 21];
        List<Crypto1State> statelist = new ArrayList<>(1 << 18);
        int oddTail = 0;
        int evenTail = 0;

        for (int i = 1 << 20; i >= 0; --i)
        {
            if (filter(i) == (oks & 1))
                odd[++oddTail] = i;
            if (filter(i) == (eks & 1))
                even[++evenTail] = i;
        }

        for (int i = 0; i < 4; i++)
        {
            oddTail = extendTableSimple(odd, oddTail, (oks >>= 1) & 1);
            evenTail = extendTableSimple(even, evenTail, (eks >>= 1) & 1);
        }

        _in = (_in >> 16 & 0xff) | (_in << 16) | (_in & 0xff00);
        recover(new Span(odd), oddTail, oks, new Span(even), evenTail, eks, 11, statelist, _in << 1);

        return statelist;
    }
}

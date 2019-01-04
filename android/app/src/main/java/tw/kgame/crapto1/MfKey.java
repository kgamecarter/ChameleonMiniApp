package tw.kgame.crapto1;

import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

import java8.util.Spliterator;
import java8.util.Spliterators;
import java8.util.stream.*;

public class MfKey {
    static long swapEndian(long x) {
        x = (x >> 8 & 0xff00ffL) | (x & 0xff00ffL) << 8;
        x &= 0xFFFFFFFFL;
        x = x >> 16 | x << 16;
        x &= 0xFFFFFFFFL;
        return x;
    }

    static long prngSuccessor(long x, int n) {
        x = swapEndian(x);
        while (n-- > 0)
            x = x >> 1 | ((x >> 16 ^ x >> 18 ^ x >> 19 ^ x >> 21) & 1) << 31;
        return swapEndian(x);
    }

    public static long mfKey32(long uid, List<Nonce> nonces) {
        Nonce nonce = nonces.get(0);
        nonces.remove(0);
        long p640 = prngSuccessor(nonce.nt, 64);
        System.out.println(Long.toHexString(p640));
        List<Crypto1State> list = Crapto1.lfsrRecovery32(nonce.ar ^ p640, 0);
        System.out.println(list.size());
        List<Long> keys = new CopyOnWriteArrayList<>();
        Spliterator<Crypto1State> sp = Spliterators.spliterator(list, Spliterator.CONCURRENT);
        StreamSupport.stream(sp, true).forEach(s -> {
            Crapto1 crapto1 = new Crapto1(s);
            crapto1.lfsrRollbackWord(0, false);
            crapto1.lfsrRollbackWord(nonce.nr, true);
            crapto1.lfsrRollbackWord(uid ^ nonce.nt, false);
            boolean allPass = true;
            Crypto1 crypto1 = new Crypto1(new Crypto1State(0, 0));
            for (Nonce n : nonces) {
                crypto1.state.odd = s.odd;
                crypto1.state.even = s.even;
                crypto1.crypto1Word(uid ^ n.nt, false);
                crypto1.crypto1Word(n.nr, true);
                long p641 = prngSuccessor(n.nt, 64);
                if (n.ar != (crypto1.crypto1Word(0, false) ^ p641)) {
                    allPass = false;
                    break;
                }
            }
            if (allPass)
                keys.add(s.getLfsr());
        });
        return keys.size() == 1 ? keys.get(0) : -1;
    }
}

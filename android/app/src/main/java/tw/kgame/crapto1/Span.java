package tw.kgame.crapto1;

import java.util.Arrays;

public class Span {
    long[] array;
    int offset;
    int length;

    public Span(long[] array) {
        this(array, 0, array.length);
    }

    public Span(long[] array, int offset, int length) {
        this.array = array;
        this.offset = offset;
        this.length = length;
    }

    public long get(int i) {
        return array[i + offset];
    }

    public void set(int i, long v) {
        array[i + offset] = v;
    }

    public Span slice(int start) {
        return new Span(array, offset + start, length - start);
    }

    public Span slice(int start, int length) {
        return new Span(array, offset + start, length);
    }

    public int binarySearch() {
        int start = 0, stop = this.length - 1, mid;
        long val = this.get(stop) & 0xff000000;
        while (start != stop)
            if (this.get(start + (mid = (stop - start) >> 1)) > val)
                stop = start + mid;
            else
                start += mid + 1;
        return start;
    }

    public void sort() {
        Arrays.sort(array, offset, offset + length);
    }
}

using Crapto1Sharp;
using System.Runtime.InteropServices;

namespace Crapto1Native;

public static class Library
{
    [UnmanagedCallersOnly(EntryPoint = "MfKey32")]
    public static unsafe ulong MfKey32(uint uid, int cnt, Nonce* nonces)
    {
        var arr = new Nonce[cnt];
        for (int i = 0; i < cnt; i++)
            arr[i] = nonces[i];
        return MfKey.MfKey32(uid, arr);
    }

    [UnmanagedCallersOnly(EntryPoint = "MfKey64")]
    public static ulong MfKey64(uint uid, uint nt, uint nr, uint ar, uint at)
        => MfKey.MfKey64(uid, nt, nr, ar, at);
}

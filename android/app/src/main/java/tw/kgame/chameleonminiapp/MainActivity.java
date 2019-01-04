package tw.kgame.chameleonminiapp;

import java.util.*;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import tw.kgame.crapto1.MfKey;
import tw.kgame.crapto1.Nonce;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "tw.kgame.crapto1/mfkey";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            (call, result) -> {
                System.out.println(call.method);
                @SuppressWarnings("unchecked")
                Map<String, Object> map = (Map<String, Object>)call.arguments;
                Object obj = map.get("uid");
                long uid = obj instanceof Long ? (long)obj : (long)(int)obj;
                @SuppressWarnings("unchecked")
                List<Map<String, Long>> ns = (List<Map<String, Long>>)map.get("nonces");
                List<Nonce> nonces = new ArrayList<>();
                for (Map<String, Long> n: ns) {
                    Nonce nonce = new Nonce();
                    obj = n.get("nt");
                    nonce.nt = obj instanceof Long ? (long)obj : (long)(int)obj;
                    obj = n.get("nr");
                    nonce.nr = obj instanceof Long ? (long)obj : (long)(int)obj;
                    obj = n.get("ar");
                    nonce.ar = obj instanceof Long ? (long)obj : (long)(int)obj;
                    nonces.add(nonce);
                }
                Thread t = new Thread(() -> {
                    try {
                        long k = MfKey.mfKey32(uid, nonces);
                        result.success(k == -1 ? null : k);
                    } catch (Exception ex) {
                        result.success(-1);
                    }
                });
                t.start();
            }
        );
    }
}

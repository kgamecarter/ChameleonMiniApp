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
    MethodChannel channel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        channel = new MethodChannel(getFlutterView(), CHANNEL);
        channel.setMethodCallHandler(
            (call, result) -> {
                System.out.println(call.method);
                @SuppressWarnings("unchecked")
                Map<String, Object> map = (Map<String, Object>)call.arguments;
                Object obj = map.get("uid");
                long uid = obj instanceof Long ? (long)obj : (long)(int)obj;
                @SuppressWarnings("unchecked")
                List<Map<String, Long>> ns = (List<Map<String, Long>>)map.get("nonces");
                List<Nonce> nonces = new ArrayList<>();
                long v = 0;
                for (Map<String, Long> n: ns) {
                    Nonce nonce = new Nonce();
                    obj = n.get("nt");
                    nonce.nt = obj instanceof Long ? (long)obj : (long)(int)obj;
                    obj = n.get("nr");
                    nonce.nr = obj instanceof Long ? (long)obj : (long)(int)obj;
                    obj = n.get("ar");
                    nonce.ar = obj instanceof Long ? (long)obj : (long)(int)obj;
                    nonces.add(nonce);
                    v ^= nonce.nt ^ nonce.nr ^ nonce.ar;
                }
                final long id = v;
                new Thread(() -> {
                    Long k = null;
                    try {
                        k = MfKey.mfKey32(uid, nonces);
                    } catch (Exception ex) {
                    }
                    Map<String, Object> m = new HashMap<String, Object>();
                    m.put("id", id);
                    m.put("key", k == -1 ? null : k);
                    runOnUiThread(() -> {
                        channel.invokeMethod("mfKey32Result", m, new MethodChannel.Result() {
                            @Override
                            public void success(Object result) {
                            }

                            @Override
                            public void error(String errorCode, String errorMessage, Object errorDetails) {
                            }

                            @Override
                            public void notImplemented() {
                            }
                        });
                    });
                }).start();
                result.success(id);
            }
        );
    }
}

package wtf.zikzak.flutterwebviewexample;

import android.os.Bundle;
import wtf.zikzak.zikzak_inappwebview_android.InAppWebViewFlutterPlugin;

@SuppressWarnings("deprecation")
public class EmbedderV1Activity extends io.flutter.app.FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    InAppWebViewFlutterPlugin.registerWith(
            registrarFor("wtf.zikzak.zikzak_inappwebview.InAppWebViewFlutterPlugin"));
  }
}

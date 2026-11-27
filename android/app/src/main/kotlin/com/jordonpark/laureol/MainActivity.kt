package com.jordonpark.laureol

import com.google.android.gms.ads.MobileAds
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.jordonpark.laureol/ads")
            .setMethodCallHandler { call, result ->
                if (call.method != "useContextualAds") {
                    result.notImplemented()
                } else if (MobileAds.putPublisherFirstPartyIdEnabled(false)) {
                    result.success(null)
                } else {
                    result.error("privacy_configuration_failed", null, null)
                }
            }
    }
}

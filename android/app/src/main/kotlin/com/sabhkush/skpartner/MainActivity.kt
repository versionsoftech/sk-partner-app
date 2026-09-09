package com.sabhkush.skpartner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(OrderAlertPlugin())
    }

    // IMPORTANT: Do NOT stop OrderAlertService here.
    // Stopping in onStart/onResume was killing the alert after one beep on Vivo
    // when FCM woke the process. Stop is done from Flutter Splash / OK / order screen.
}

package com.sabhkush.skpartner

import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver

/**
 * Replaces FlutterFire's C2DM receiver so we start the continuous order alert
 * immediately in native code (works when Flutter is killed / not opened),
 * then forward to FlutterFire for normal Dart handling.
 */
class SkPartnerFirebaseMessagingReceiver : FlutterFirebaseMessagingReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        var wakeLock: PowerManager.WakeLock? = null
        try {
            wakeLock = (context.getSystemService(Context.POWER_SERVICE) as PowerManager)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "skpartner:FcmAlertWake")
                .also {
                    it.setReferenceCounted(false)
                    it.acquire(30_000L)
                }

            val extras = intent.extras
            if (extras != null) {
                val message = RemoteMessage(extras)
                val data = message.data
                val title = message.notification?.title ?: data["title"]
                val body = message.notification?.body
                    ?: data["body"]
                    ?: data["description"]
                Log.i(TAG, "FCM type=${data["type"]} title=$title order_id=${data["order_id"]}")

                if (OrderAlertService.shouldAlert(data, title, body)) {
                    val orderId = data["order_id"] ?: data["title_loc_key"]
                    OrderAlertService.start(context, orderId)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "native alert start failed", e)
        } finally {
            try {
                // Always let FlutterFire process the message (background Dart / foreground stream).
                super.onReceive(context, intent)
            } catch (e: Exception) {
                Log.e(TAG, "FlutterFire onReceive failed", e)
            }
            try {
                if (wakeLock?.isHeld == true) wakeLock.release()
            } catch (_: Exception) {
            }
            pending.finish()
        }
    }

    companion object {
        private const val TAG = "SkPartnerFcmReceiver"
    }
}

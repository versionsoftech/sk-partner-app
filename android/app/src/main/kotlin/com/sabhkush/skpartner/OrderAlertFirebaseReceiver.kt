package com.sabhkush.skpartner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.RemoteMessage

/**
 * Backup C2DM receiver — starts continuous alert if the primary FCM receiver is delayed.
 */
class OrderAlertFirebaseReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val extras = intent?.extras ?: return
        try {
            val message = RemoteMessage(extras)
            val data = message.data
            val title = message.notification?.title ?: data["title"]
            val body = message.notification?.body ?: data["body"] ?: data["description"]
            Log.i(TAG, "backup C2DM type=${data["type"]} title=$title order_id=${data["order_id"]}")

            if (OrderAlertService.shouldAlert(data, title, body)) {
                val pending = goAsync()
                try {
                    OrderAlertService.start(context, data["order_id"])
                } finally {
                    pending.finish()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "backup C2DM handle failed", e)
        }
    }

    companion object {
        private const val TAG = "OrderAlertFcmReceiver"
    }
}

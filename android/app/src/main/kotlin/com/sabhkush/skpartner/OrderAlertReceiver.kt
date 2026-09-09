package com.sabhkush.skpartner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/** Starts/stops native order alert from Flutter broadcasts / method channel helpers. */
class OrderAlertReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i(TAG, "Received action=${intent?.action}")
        when (intent?.action) {
            OrderAlertService.ACTION_START -> {
                val orderId = intent.getStringExtra(OrderAlertService.EXTRA_ORDER_ID)
                OrderAlertService.start(context, orderId)
            }
            OrderAlertService.ACTION_STOP -> {
                OrderAlertService.stop(context)
            }
        }
    }

    companion object {
        private const val TAG = "OrderAlertReceiver"
    }
}

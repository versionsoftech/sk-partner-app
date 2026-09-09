package com.sabhkush.skpartner

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class OrderAlertPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var appContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext
        if (context == null) {
            result.error("no_context", "App context not ready", null)
            return
        }
        when (call.method) {
            "start" -> {
                OrderAlertService.start(context, call.argument("orderId"))
                result.success(true)
            }
            "stop" -> {
                OrderAlertService.stop(context)
                result.success(true)
            }
            "isBatteryOptimizationIgnored" -> {
                result.success(OrderAlertOemHelper.isIgnoringBatteryOptimizations(context))
            }
            "requestIgnoreBatteryOptimizations" -> {
                result.success(OrderAlertOemHelper.requestIgnoreBatteryOptimizations(context))
            }
            "openAutostartSettings" -> {
                result.success(OrderAlertOemHelper.openAutostartSettings(context))
            }
            "openAppBatterySettings" -> {
                result.success(OrderAlertOemHelper.openAppBatterySettings(context))
            }
            "openAppDetails" -> {
                result.success(OrderAlertOemHelper.openAppDetails(context))
            }
            "getDeviceGuide" -> {
                result.success(OrderAlertOemHelper.openManufacturerGuide(context))
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "sk_partner/order_alert"
    }
}

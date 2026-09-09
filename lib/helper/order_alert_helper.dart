import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart_store/helper/custom_print_helper.dart';

/// Controls the native continuous order alert service on Android.
class OrderAlertHelper {
  OrderAlertHelper._();

  static const MethodChannel _channel = MethodChannel('sk_partner/order_alert');

  static bool shouldStartAlert(
    Map<String, dynamic> data, {
    String? notificationTitle,
    String? notificationBody,
  }) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    final orderId = data['order_id']?.toString();
    final title = '${data['title'] ?? notificationTitle ?? ''}'.toLowerCase();
    final body = '${data['body'] ?? data['description'] ?? notificationBody ?? ''}'.toLowerCase();
    final text = '$title $body';

    const skipWords = <String>[
      'delivered',
      'completed',
      'cancelled',
      'canceled',
      'refund',
      'rejected',
      'handover',
      'picked up',
      'out for delivery',
      'on the way',
      'cooking',
      'preparing',
    ];
    for (final word in skipWords) {
      if (text.contains(word)) return false;
    }

    if (type == 'new_order' || type == 'order_status' || type == 'order') return true;
    if (orderId != null && orderId.isNotEmpty && orderId != 'null') return true;
    if (text.contains('new order') || text.contains('order placed')) return true;
    if (text.contains('paid') || text.contains('payment') || text.contains('order')) return true;
    return false;
  }

  static bool shouldStartAlertFromMessage(RemoteMessage message) {
    return shouldStartAlert(
      Map<String, dynamic>.from(message.data),
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
    );
  }

  static Future<void> start(String? orderId) async {
    if (!Platform.isAndroid) return;
    customPrint('OrderAlertHelper.start orderId=$orderId');

    // Broadcast first — works even when MethodChannel plugins are not registered
    // (FCM background isolate).
    await _broadcastStart(orderId);

    try {
      await _channel.invokeMethod('start', {'orderId': orderId ?? ''});
    } catch (e) {
      customPrint('OrderAlert channel start failed: $e');
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    customPrint('OrderAlertHelper.stop');

    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}

    try {
      final intent = AndroidIntent(
        action: 'com.sabhkush.skpartner.STOP_ORDER_ALERT',
        package: 'com.sabhkush.skpartner',
      );
      await intent.sendBroadcast();
    } catch (_) {}
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  static Future<void> openAutostartSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAutostartSettings');
    } catch (_) {}
  }

  static Future<void> openAppBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAppBatterySettings');
    } catch (_) {}
  }

  static Future<void> openAppDetails() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAppDetails');
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getDeviceGuide() async {
    if (!Platform.isAndroid) return <String, dynamic>{};
    try {
      final result = await _channel.invokeMethod<dynamic>('getDeviceGuide');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  static Future<void> _broadcastStart(String? orderId) async {
    try {
      final intent = AndroidIntent(
        action: 'com.sabhkush.skpartner.START_ORDER_ALERT',
        package: 'com.sabhkush.skpartner',
        arguments: <String, dynamic>{'orderId': orderId ?? ''},
      );
      await intent.sendBroadcast();
    } catch (e) {
      customPrint('OrderAlert broadcast start failed: $e');
    }
  }
}

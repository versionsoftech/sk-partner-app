import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart_store/helper/order_alert_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

/// One-time (and on-demand) setup so continuous new-order beep works when
/// the app is minimized / cleared on OEM phones (Xiaomi, Vivo, Oppo, Samsung…).
class OrderAlertSetupDialog extends StatefulWidget {
  const OrderAlertSetupDialog({super.key});

  static const String prefsKey = 'order_alert_setup_done_v1';

  static Future<void> showIfNeeded() async {
    if (!GetPlatform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(prefsKey) == true) {
      final ignored = await OrderAlertHelper.isBatteryOptimizationIgnored();
      if (ignored) return;
    }
    if (Get.isDialogOpen == true) return;
    await Get.dialog(const OrderAlertSetupDialog(), barrierDismissible: false);
  }

  static Future<void> showNow() async {
    if (!GetPlatform.isAndroid) return;
    if (Get.isDialogOpen == true) return;
    await Get.dialog(const OrderAlertSetupDialog(), barrierDismissible: true);
  }

  @override
  State<OrderAlertSetupDialog> createState() => _OrderAlertSetupDialogState();
}

class _OrderAlertSetupDialogState extends State<OrderAlertSetupDialog> {
  String _tip = 'Allow background activity / unrestricted battery for SabhKush Partner.';
  bool _batteryOk = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final guide = await OrderAlertHelper.getDeviceGuide();
    final batteryOk = await OrderAlertHelper.isBatteryOptimizationIgnored();
    if (!mounted) return;
    setState(() {
      _tip = (guide['tip'] ?? _tip).toString();
      _batteryOk = batteryOk;
      _loading = false;
    });
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OrderAlertSetupDialog.prefsKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enable continuous order alert', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'So new orders keep beeping when the app is closed, minimized, or cleared, please allow these permissions:',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(_tip, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _step('1. Notification permission', _requestNotification),
                  _step(
                    _batteryOk ? '2. Battery unrestricted ✓' : '2. Allow ignore battery optimization',
                    OrderAlertHelper.requestIgnoreBatteryOptimizations,
                  ),
                  _step('3. Autostart / background activity (OEM)', OrderAlertHelper.openAutostartSettings),
                  _step('4. App battery settings', OrderAlertHelper.openAppBatterySettings),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () async {
            await _markDone();
            Get.back();
          },
          child: Text('not_now'.tr),
        ),
        ElevatedButton(
          onPressed: () async {
            await Permission.notification.request();
            await OrderAlertHelper.requestIgnoreBatteryOptimizations();
            await OrderAlertHelper.openAutostartSettings();
            await _markDone();
            await _load();
            if (Get.isDialogOpen == true) Get.back();
          },
          child: Text('allow'.tr),
        ),
      ],
    );
  }

  Widget _step(String label, Future<void> Function() onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: () async {
          await onTap();
          await Future.delayed(const Duration(milliseconds: 600));
          await _load();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
              Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      await openAppSettings();
    }
  }
}

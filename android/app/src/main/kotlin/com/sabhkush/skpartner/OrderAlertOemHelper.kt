package com.sabhkush.skpartner

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Opens battery / autostart screens across OEMs so continuous order alerts can run
 * when the app is minimized or cleared from recents.
 */
object OrderAlertOemHelper {
    private const val TAG = "OrderAlertOemHelper"

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        return try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(context.packageName)
        } catch (_: Exception) {
            false
        }
    }

    @SuppressLint("BatteryLife")
    fun requestIgnoreBatteryOptimizations(context: Context): Boolean {
        return try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
            if (isIgnoringBatteryOptimizations(context)) return true
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "requestIgnoreBatteryOptimizations failed", e)
            openAppBatterySettings(context)
        }
    }

    fun openAppBatterySettings(context: Context): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                return true
            }
            openAppDetails(context)
        } catch (e: Exception) {
            Log.e(TAG, "openAppBatterySettings failed", e)
            openAppDetails(context)
        }
    }

    fun openAppDetails(context: Context): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "openAppDetails failed", e)
            false
        }
    }

    /** Tries OEM autostart / background activity screens, then falls back to app details. */
    fun openAutostartSettings(context: Context): Boolean {
        val pkg = context.packageName
        val candidates = mutableListOf<Intent>()

        // Xiaomi / Redmi / Poco
        candidates += Intent().setComponent(
            ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            )
        )
        candidates += Intent("miui.intent.action.OP_AUTO_START").setPackage("com.miui.securitycenter")

        // Oppo / Realme
        candidates += Intent().setComponent(
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity"
            )
        )
        candidates += Intent().setComponent(
            ComponentName(
                "com.oplus.battery",
                "com.oplus.startupapp.view.StartupAppListActivity"
            )
        )
        candidates += Intent().setComponent(
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.startupapp.StartupAppListActivity"
            )
        )

        // Vivo
        candidates += Intent().setComponent(
            ComponentName(
                "com.iqoo.secure",
                "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
            )
        )
        candidates += Intent().setComponent(
            ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            )
        )

        // Huawei / Honor
        candidates += Intent().setComponent(
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            )
        )
        candidates += Intent().setComponent(
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.optimize.process.ProtectActivity"
            )
        )

        // Samsung
        candidates += Intent().setComponent(
            ComponentName(
                "com.samsung.android.lool",
                "com.samsung.android.sm.ui.battery.BatteryActivity"
            )
        )
        candidates += Intent().setComponent(
            ComponentName(
                "com.samsung.android.sm",
                "com.samsung.android.sm.ui.battery.BatteryActivity"
            )
        )

        // OnePlus
        candidates += Intent().setComponent(
            ComponentName(
                "com.oneplus.security",
                "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
            )
        )

        // LetB / Techno / Infinix
        candidates += Intent().setComponent(
            ComponentName(
                "com.letv.android.letvsafe",
                "com.letv.android.letvsafe.AutobootManageActivity"
            )
        )
        candidates += Intent().setComponent(
            ComponentName(
                "com.transsion.phonemanager",
                "com.itel.powerkeeping.fuel.ui.PowerKeepingActivity"
            )
        )

        for (intent in candidates) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
            }
        }

        // Generic: app details where user can set battery unrestricted
        return openAppDetails(context)
    }

    fun openManufacturerGuide(context: Context): Map<String, Any> {
        val manufacturer = Build.MANUFACTURER.orEmpty().lowercase()
        val brand = Build.BRAND.orEmpty().lowercase()
        val tip = when {
            manufacturer.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") ->
                "Open Autostart → ON, and Battery saver → No restrictions for SabhKush Partner."
            manufacturer.contains("oppo") || brand.contains("realme") || brand.contains("oneplus") ->
                "App info → Battery → Allow background activity ON. Also enable Autostart."
            manufacturer.contains("vivo") || brand.contains("iqoo") ->
                "Battery → Background power consumption → Unrestricted / High. Enable Autostart."
            manufacturer.contains("samsung") ->
                "Apps → SabhKush Partner → Battery → Unrestricted. Remove from sleeping apps."
            manufacturer.contains("huawei") || manufacturer.contains("honor") ->
                "App launch → Manage manually → enable Auto-launch, Secondary launch, Run in background."
            else ->
                "App info → Battery → Unrestricted / Allow background activity for SabhKush Partner."
        }
        return mapOf(
            "manufacturer" to Build.MANUFACTURER.orEmpty(),
            "brand" to Build.BRAND.orEmpty(),
            "model" to Build.MODEL.orEmpty(),
            "tip" to tip,
            "batteryIgnored" to isIgnoringBatteryOptimizations(context),
        )
    }
}

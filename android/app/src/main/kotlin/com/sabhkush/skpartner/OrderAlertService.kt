package com.sabhkush.skpartner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Continuous order alert for vendor phones across OEMs.
 * Uses looping alarm-stream audio + vibration until stop() when the app UI opens.
 */
class OrderAlertService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var musicPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var toneGenerator: ToneGenerator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var orderId: String = ""
    private var running = false
    private var usingToneFallback = false
    private var volumeBoosted = false
    private var savedAlarmVolume = -1
    private var savedRingVolume = -1
    private var savedNotificationVolume = -1
    private var savedMusicVolume = -1
    private var savedRingerMode = -1
    private var savedSpeakerphone = false

    private val volumeWatchdogRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            boostVolumeToMax()
            handler.postDelayed(this, VOLUME_WATCHDOG_MS)
        }
    }

    private val toneFallbackRunnable = object : Runnable {
        override fun run() {
            if (!running || !usingToneFallback) return
            playToneOnce()
            handler.postDelayed(this, BEEP_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            Log.i(TAG, "STOP action received")
            stopAlertInternal()
            stopSelf()
            return START_NOT_STICKY
        }

        orderId = intent?.getStringExtra(EXTRA_ORDER_ID) ?: orderId
        Log.i(TAG, "START action orderId=$orderId")

        createChannel()
        startAsForeground(buildNotification(orderId))
        acquireWakeLock()
        requestAudioFocus()
        boostVolumeToMax()

        if (!running) {
            running = true
            isRunning = true
            startContinuousAlert()
            handler.removeCallbacks(volumeWatchdogRunnable)
            handler.postDelayed(volumeWatchdogRunnable, VOLUME_WATCHDOG_MS)
        }
        // Sticky: restart if OEM kills the process while alert is active
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // App swiped from recents — keep ringing if still marked active
        val active = getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(PREF_ACTIVE, false)
        Log.i(TAG, "onTaskRemoved active=$active")
        if (active && !running) {
            OrderAlertService.start(applicationContext, orderId)
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        val shouldRestart = getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(PREF_ACTIVE, false)
        // Keep boosted volume if we are about to restart; restore only when the vendor stops the alert.
        stopAlertInternal(clearActiveFlag = false, restoreVol = !shouldRestart)
        super.onDestroy()
        if (shouldRestart) {
            Log.i(TAG, "Service destroyed while active — restarting")
            handler.postDelayed({
                try {
                    start(applicationContext, orderId)
                } catch (e: Exception) {
                    Log.e(TAG, "restart after destroy failed", e)
                }
            }, 400L)
        }
    }

    private fun startContinuousAlert() {
        if (startLoopingRaw() || startLoopingSystemAlarm()) {
            usingToneFallback = false
            startVibrationLoop()
            return
        }
        usingToneFallback = true
        startVibrationLoop()
        handler.removeCallbacks(toneFallbackRunnable)
        handler.post(toneFallbackRunnable)
    }

    private fun startLoopingRaw(): Boolean {
        return try {
            releasePlayer()
            mediaPlayer = createLoopingPlayer(
                AudioAttributes.USAGE_ALARM,
                AudioManager.STREAM_ALARM
            )
            try {
                musicPlayer = createLoopingPlayer(
                    AudioAttributes.USAGE_MEDIA,
                    AudioManager.STREAM_MUSIC
                )
            } catch (e: Exception) {
                Log.e(TAG, "music stream player failed", e)
            }
            mediaPlayer != null
        } catch (e: Exception) {
            Log.e(TAG, "startLoopingRaw failed", e)
            releasePlayer()
            false
        }
    }

    private fun createLoopingPlayer(usage: Int, stream: Int): MediaPlayer {
        val player = MediaPlayer()
        player.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(usage)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setLegacyStreamType(stream)
                .build()
        )
        val afd = resources.openRawResourceFd(R.raw.order_alert)
        player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        afd.close()
        player.isLooping = true
        player.setVolume(1f, 1f)
        player.prepare()
        player.start()
        return player
    }

    private fun startLoopingSystemAlarm(): Boolean {
        return try {
            releasePlayer()
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: return false
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setLegacyStreamType(AudioManager.STREAM_ALARM)
                    .build()
            )
            player.setDataSource(applicationContext, uri)
            player.isLooping = true
            player.setVolume(1f, 1f)
            player.prepare()
            player.start()
            mediaPlayer = player
            true
        } catch (e: Exception) {
            Log.e(TAG, "startLoopingSystemAlarm failed", e)
            releasePlayer()
            false
        }
    }

    private fun playToneOnce() {
        try {
            if (toneGenerator == null) {
                toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
            }
            toneGenerator?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 700)
        } catch (e: Exception) {
            Log.e(TAG, "playToneOnce failed", e)
            try {
                toneGenerator?.release()
            } catch (_: Exception) {
            }
            toneGenerator = null
        }
    }

    private fun startVibrationLoop() {
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            val pattern = longArrayOf(0, 700, 500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startVibrationLoop failed", e)
        }
    }

    private fun startAsForeground(notification: Notification) {
        try {
            when {
                Build.VERSION.SDK_INT >= 34 -> {
                    ServiceCompat.startForeground(
                        this,
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING or
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    ServiceCompat.startForeground(
                        this,
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                    )
                }
                else -> startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "typed startForeground failed", e)
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (e2: Exception) {
                Log.e(TAG, "plain startForeground failed", e2)
            }
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock?.isHeld == true) return
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "skpartner:OrderAlertWakeLock"
            ).also {
                it.setReferenceCounted(false)
                it.acquire(60 * 60 * 1000L)
            }
        } catch (e: Exception) {
            Log.e(TAG, "wakeLock failed", e)
        }
    }

    private fun boostVolumeToMax() {
        try {
            if (audioManager == null) {
                audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            }
            val am = audioManager ?: return
            if (!volumeBoosted) {
                val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                if (prefs.getBoolean(PREF_VOL_SAVED, false)) {
                    savedAlarmVolume = prefs.getInt(PREF_ALARM_VOL, am.getStreamVolume(AudioManager.STREAM_ALARM))
                    savedRingVolume = prefs.getInt(PREF_RING_VOL, am.getStreamVolume(AudioManager.STREAM_RING))
                    savedNotificationVolume = prefs.getInt(PREF_NOTIF_VOL, am.getStreamVolume(AudioManager.STREAM_NOTIFICATION))
                    savedMusicVolume = prefs.getInt(PREF_MUSIC_VOL, am.getStreamVolume(AudioManager.STREAM_MUSIC))
                    savedRingerMode = prefs.getInt(PREF_RINGER_MODE, am.ringerMode)
                    savedSpeakerphone = prefs.getBoolean(PREF_SPEAKER, false)
                } else {
                    savedAlarmVolume = am.getStreamVolume(AudioManager.STREAM_ALARM)
                    savedRingVolume = am.getStreamVolume(AudioManager.STREAM_RING)
                    savedNotificationVolume = am.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
                    savedMusicVolume = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                    savedRingerMode = am.ringerMode
                    savedSpeakerphone = am.isSpeakerphoneOn
                    prefs.edit()
                        .putBoolean(PREF_VOL_SAVED, true)
                        .putInt(PREF_ALARM_VOL, savedAlarmVolume)
                        .putInt(PREF_RING_VOL, savedRingVolume)
                        .putInt(PREF_NOTIF_VOL, savedNotificationVolume)
                        .putInt(PREF_MUSIC_VOL, savedMusicVolume)
                        .putInt(PREF_RINGER_MODE, savedRingerMode)
                        .putBoolean(PREF_SPEAKER, savedSpeakerphone)
                        .apply()
                }
                volumeBoosted = true
            }
            try {
                if (am.ringerMode != AudioManager.RINGER_MODE_NORMAL) {
                    am.ringerMode = AudioManager.RINGER_MODE_NORMAL
                }
            } catch (_: Exception) {
            }
            maxOutStream(am, AudioManager.STREAM_ALARM)
            maxOutStream(am, AudioManager.STREAM_RING)
            maxOutStream(am, AudioManager.STREAM_NOTIFICATION)
            maxOutStream(am, AudioManager.STREAM_MUSIC)
            try {
                am.mode = AudioManager.MODE_NORMAL
                am.isSpeakerphoneOn = true
            } catch (_: Exception) {
            }
            mediaPlayer?.setVolume(1f, 1f)
            musicPlayer?.setVolume(1f, 1f)
        } catch (e: Exception) {
            Log.e(TAG, "boostVolumeToMax failed", e)
        }
    }

    private fun maxOutStream(am: AudioManager, stream: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (am.isStreamMute(stream)) {
                    am.adjustStreamVolume(stream, AudioManager.ADJUST_UNMUTE, 0)
                }
            }
            val max = am.getStreamMaxVolume(stream)
            if (max > 0) {
                am.setStreamVolume(stream, max, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "maxOutStream $stream failed", e)
        }
    }

    private fun restoreVolume() {
        try {
            val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val hasSaved = volumeBoosted || prefs.getBoolean(PREF_VOL_SAVED, false)
            if (!hasSaved) return
            val am = audioManager ?: getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val alarm = if (savedAlarmVolume >= 0) savedAlarmVolume else prefs.getInt(PREF_ALARM_VOL, -1)
            val ring = if (savedRingVolume >= 0) savedRingVolume else prefs.getInt(PREF_RING_VOL, -1)
            val notif = if (savedNotificationVolume >= 0) savedNotificationVolume else prefs.getInt(PREF_NOTIF_VOL, -1)
            val music = if (savedMusicVolume >= 0) savedMusicVolume else prefs.getInt(PREF_MUSIC_VOL, -1)
            val ringer = if (savedRingerMode >= 0) savedRingerMode else prefs.getInt(PREF_RINGER_MODE, -1)
            if (alarm >= 0) am.setStreamVolume(AudioManager.STREAM_ALARM, alarm, 0)
            if (ring >= 0) am.setStreamVolume(AudioManager.STREAM_RING, ring, 0)
            if (notif >= 0) am.setStreamVolume(AudioManager.STREAM_NOTIFICATION, notif, 0)
            if (music >= 0) am.setStreamVolume(AudioManager.STREAM_MUSIC, music, 0)
            if (ringer >= 0) {
                try {
                    am.ringerMode = ringer
                } catch (_: Exception) {
                }
            }
            try {
                am.isSpeakerphoneOn = if (volumeBoosted) savedSpeakerphone else prefs.getBoolean(PREF_SPEAKER, false)
            } catch (_: Exception) {
            }
            prefs.edit()
                .putBoolean(PREF_VOL_SAVED, false)
                .remove(PREF_ALARM_VOL)
                .remove(PREF_RING_VOL)
                .remove(PREF_NOTIF_VOL)
                .remove(PREF_MUSIC_VOL)
                .remove(PREF_RINGER_MODE)
                .remove(PREF_SPEAKER)
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "restoreVolume failed", e)
        }
        volumeBoosted = false
        savedAlarmVolume = -1
        savedRingVolume = -1
        savedNotificationVolume = -1
        savedMusicVolume = -1
        savedRingerMode = -1
        savedSpeakerphone = false
    }

    private fun requestAudioFocus() {
        try {
            audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = android.media.AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .build()
                audioManager?.requestAudioFocus(focusRequest)
            } else {
                @Suppress("DEPRECATION")
                audioManager?.requestAudioFocus(
                    null,
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "audio focus failed", e)
        }
    }

    private fun releasePlayer() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null
        try {
            musicPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            musicPlayer?.release()
        } catch (_: Exception) {
        }
        musicPlayer = null
    }

    private fun stopAlertInternal(clearActiveFlag: Boolean = true, restoreVol: Boolean = true) {
        running = false
        isRunning = false
        usingToneFallback = false
        handler.removeCallbacks(toneFallbackRunnable)
        handler.removeCallbacks(volumeWatchdogRunnable)
        if (restoreVol) {
            restoreVolume()
        }
        releasePlayer()
        try {
            toneGenerator?.release()
        } catch (_: Exception) {
        }
        toneGenerator = null
        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
        vibrator = null
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {
        }
        wakeLock = null
        if (clearActiveFlag) {
            getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(PREF_ACTIVE, false)
                .apply()
        }
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } catch (_: Exception) {
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "New Order Alert",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Continuous alert until you open the app"
                setSound(null, null)
                enableVibration(false)
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(orderId: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("from_order_alert", true)
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val title = if (orderId.isNotEmpty()) "New order #$orderId" else "New order waiting!"
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText("Open SabhKush Partner to stop alert and view order")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentIntent(pending)
            .setOngoing(true)
            .setAutoCancel(false)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    companion object {
        private const val TAG = "OrderAlertService"
        private const val BEEP_INTERVAL_MS = 1200L
        private const val VOLUME_WATCHDOG_MS = 1500L
        const val CHANNEL_ID = "sk_partner_native_order_alert_v5"
        const val NOTIFICATION_ID = 2601
        const val EXTRA_ORDER_ID = "orderId"
        const val ACTION_STOP = "com.sabhkush.skpartner.STOP_ORDER_ALERT"
        const val ACTION_START = "com.sabhkush.skpartner.START_ORDER_ALERT"
        private const val PREFS = "sk_order_alert"
        private const val PREF_ACTIVE = "active"
        private const val PREF_STARTED_AT = "started_at"
        private const val PREF_VOL_SAVED = "vol_saved"
        private const val PREF_ALARM_VOL = "alarm_vol"
        private const val PREF_RING_VOL = "ring_vol"
        private const val PREF_NOTIF_VOL = "notif_vol"
        private const val PREF_MUSIC_VOL = "music_vol"
        private const val PREF_RINGER_MODE = "ringer_mode"
        private const val PREF_SPEAKER = "speaker"

        @Volatile
        var isRunning: Boolean = false

        fun start(context: Context, orderId: String?) {
            Log.i(TAG, "start() orderId=$orderId")
            val appContext = context.applicationContext
            appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(PREF_ACTIVE, true)
                .putLong(PREF_STARTED_AT, System.currentTimeMillis())
                .apply()

            val intent = Intent(appContext, OrderAlertService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_ORDER_ID, orderId ?: "")
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    appContext.startForegroundService(intent)
                } else {
                    appContext.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "startForegroundService failed, trying startService", e)
                try {
                    appContext.startService(intent)
                } catch (e2: Exception) {
                    Log.e(TAG, "startService also failed", e2)
                }
            }
        }

        fun stop(context: Context) {
            Log.i(TAG, "stop()")
            val appContext = context.applicationContext
            appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(PREF_ACTIVE, false)
                .apply()
            try {
                val intent = Intent(appContext, OrderAlertService::class.java).apply {
                    action = ACTION_STOP
                }
                appContext.startService(intent)
            } catch (_: Exception) {
            }
            try {
                appContext.stopService(Intent(appContext, OrderAlertService::class.java))
            } catch (_: Exception) {
            }
            isRunning = false
        }

        fun shouldAlert(data: Map<String, String>, title: String?, body: String?): Boolean {
            val type = (data["type"] ?: "").lowercase()
            val orderId = data["order_id"]
            val text = listOf(
                title,
                body,
                data["title"],
                data["body"],
                data["description"],
                data["message"]
            ).filterNotNull().joinToString(" ").lowercase()

            Log.i(TAG, "shouldAlert type=$type orderId=$orderId text=$text")

            val skip = listOf(
                "delivered", "completed", "cancelled", "canceled", "refund",
                "rejected", "handover", "picked up", "out for delivery", "on the way",
                "cooking", "preparing"
            )
            if (skip.any { text.contains(it) }) {
                Log.i(TAG, "shouldAlert=false (skip word)")
                return false
            }

            if (type == "new_order" || type == "order_status" || type == "order") {
                Log.i(TAG, "shouldAlert=true (type)")
                return true
            }
            if (!orderId.isNullOrBlank() && orderId != "null") {
                Log.i(TAG, "shouldAlert=true (order_id present)")
                return true
            }
            if (text.contains("new order") || text.contains("order placed") ||
                text.contains("order notification") || text.contains("paid") ||
                text.contains("payment") || text.contains("order")
            ) {
                Log.i(TAG, "shouldAlert=true (text)")
                return true
            }
            Log.i(TAG, "shouldAlert=false")
            return false
        }
    }
}

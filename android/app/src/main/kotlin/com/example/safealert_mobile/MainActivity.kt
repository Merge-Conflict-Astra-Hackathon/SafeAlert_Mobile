package com.example.safealert_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "safealert/device_alert"
    private val notificationChannelId = "safealert_emergency"
    private var previousBrightness: Float? = null
    private var previousRingerMode: Int? = null
    private val previousVolumes = mutableMapOf<Int, Int>()
    private var alarmPlayer: MediaPlayer? = null
    private var alertModeActive = false
    private val volumeHandler = Handler(Looper.getMainLooper())
    private var volumeEnforcer: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createEmergencyNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "activateAlertMode" -> {
                        activateAlertMode()
                        result.success(null)
                    }
                    "restoreAlertMode" -> {
                        restoreAlertMode()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun activateAlertMode() {
        if (alertModeActive) return
        alertModeActive = true

        previousBrightness = window.attributes.screenBrightness
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.attributes = window.attributes.apply {
            screenBrightness = 1.0f
        }

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val streams = listOf(
            AudioManager.STREAM_MUSIC,
            AudioManager.STREAM_ALARM,
            AudioManager.STREAM_RING,
            AudioManager.STREAM_NOTIFICATION,
        )

        previousRingerMode = audioManager.ringerMode
        try {
            audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
        } catch (_: SecurityException) {
            // Some devices block ringer changes while Do Not Disturb is active.
        }

        streams.forEach { stream ->
            try {
                if (!previousVolumes.containsKey(stream)) {
                    previousVolumes[stream] = audioManager.getStreamVolume(stream)
                }
                audioManager.setStreamVolume(
                    stream,
                    audioManager.getStreamMaxVolume(stream),
                    0,
                )
            } catch (_: SecurityException) {
                // Keep the alert screen alive even if the OS rejects volume changes.
            }
        }

        startVolumeEnforcer(audioManager, streams)
        startAlarmSound()
        startEmergencyVibration()
    }

    private fun restoreAlertMode() {
        if (!alertModeActive) return
        alertModeActive = false

        stopAlarmSound()
        stopEmergencyVibration()
        stopVolumeEnforcer()

        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        previousBrightness?.let { brightness ->
            window.attributes = window.attributes.apply {
                screenBrightness = brightness
            }
        }
        previousBrightness = null

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        previousVolumes.forEach { (stream, volume) ->
            try {
                audioManager.setStreamVolume(stream, volume, 0)
            } catch (_: SecurityException) {
                // Ignore restore failures; Android may lock volume under DND.
            }
        }
        previousVolumes.clear()

        previousRingerMode?.let { mode ->
            try {
                audioManager.ringerMode = mode
            } catch (_: SecurityException) {
                // Ignore restore failures for the same reason as activation.
            }
        }
        previousRingerMode = null
    }

    override fun onDestroy() {
        restoreAlertMode()
        super.onDestroy()
    }

    private fun createEmergencyNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            notificationChannelId,
            "SafeAlert Emergency",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarm darurat SafeAlert"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 1000, 300, 1000, 300, 1000)
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun startAlarmSound() {
        stopAlarmSound()

        try {
            val afd = resources.openRawResourceFd(R.raw.alert)
            alarmPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                isLooping = true
                prepare()
                start()
            }
            afd.close()
        } catch (_: Exception) {
            alarmPlayer?.release()
            alarmPlayer = null
        }
    }

    private fun startVolumeEnforcer(audioManager: AudioManager, streams: List<Int>) {
        stopVolumeEnforcer()
        volumeEnforcer = object : Runnable {
            override fun run() {
                if (!alertModeActive) return

                streams.forEach { stream ->
                    try {
                        audioManager.setStreamVolume(
                            stream,
                            audioManager.getStreamMaxVolume(stream),
                            0,
                        )
                    } catch (_: SecurityException) {
                        // Android may block this under Do Not Disturb or device policy.
                    }
                }

                volumeHandler.postDelayed(this, 500)
            }
        }
        volumeEnforcer?.let { volumeHandler.post(it) }
    }

    private fun stopVolumeEnforcer() {
        volumeEnforcer?.let { volumeHandler.removeCallbacks(it) }
        volumeEnforcer = null
    }

    private fun stopAlarmSound() {
        try {
            alarmPlayer?.stop()
        } catch (_: IllegalStateException) {
            // Player may already be stopped by the OS.
        }
        alarmPlayer?.release()
        alarmPlayer = null
    }

    private fun startEmergencyVibration() {
        val pattern = longArrayOf(0, 1000, 300, 1000, 300, 1000, 600)
        val vibrator = getVibrator()
        if (!vibrator.hasVibrator()) return

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val amplitudes = intArrayOf(0, 255, 0, 255, 0, 255, 0)
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, amplitudes, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, 0)
            }
        } catch (_: SecurityException) {
            // Vibration permission or device policy may block this on some devices.
        }
    }

    private fun stopEmergencyVibration() {
        try {
            getVibrator().cancel()
        } catch (_: SecurityException) {
            // Ignore restore failures.
        }
    }

    private fun getVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }
}

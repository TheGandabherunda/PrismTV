package org.thegandabherunda.prismtv

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val UPDATE_CHANNEL = "org.thegandabherunda.prismtv/app_updater"
    private val DEVICE_CONTROL_CHANNEL = "org.thegandabherunda.prismtv/device_control"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Explicitly allow screenshots, screen recording, and casting (no FLAG_SECURE)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. App Updater Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(packageName, 0)
                        }
                        result.success(pInfo.versionName ?: "1.0.1")
                    } catch (e: Exception) {
                        result.success("1.0.1")
                    }
                }
                "getDeviceAbi" -> {
                    val abi = if (Build.SUPPORTED_ABIS.isNotEmpty()) Build.SUPPORTED_ABIS[0] else "arm64-v8a"
                    result.success(abi)
                }
                "getCacheDir" -> {
                    val cache = externalCacheDir ?: cacheDir
                    result.success(cache.absolutePath)
                }
                "canInstallUnknownApps" -> {
                    val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(canInstall)
                }
                "openUnknownSourcesSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            val file = File(filePath)
                            if (!file.exists()) {
                                result.error("FILE_NOT_FOUND", "APK file does not exist at path: $filePath", null)
                                return@setMethodCallHandler
                            }

                            // Ensure file is readable by installer process
                            file.setReadable(true, false)

                            // Check permission on Android 8.0+
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                                val manageIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                    data = Uri.parse("package:$packageName")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(manageIntent)
                                result.error("PERMISSION_REQUIRED", "Please allow unknown app installation for PrismTV, then tap Install again.", null)
                                return@setMethodCallHandler
                            }

                            val apkUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                FileProvider.getUriForFile(this@MainActivity, "${packageName}.fileprovider", file)
                            } else {
                                Uri.fromFile(file)
                            }

                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(apkUri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            }

                            val resolveInfoList = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                            for (resolveInfo in resolveInfoList) {
                                val targetPkg = resolveInfo.activityInfo.packageName
                                grantUriPermission(targetPkg, apkUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }

                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Hardware Device Controls (Brightness & Volume with 0ms OS overhead)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> {
                    try {
                        val lp = window.attributes
                        val b = if (lp.screenBrightness >= 0f) {
                            lp.screenBrightness
                        } else {
                            try {
                                Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0f
                            } catch (_: Exception) {
                                0.5f
                            }
                        }
                        result.success(b.toDouble())
                    } catch (e: Exception) {
                        result.error("BRIGHTNESS_ERROR", e.localizedMessage, null)
                    }
                }
                "setBrightness" -> {
                    try {
                        val level = call.argument<Double>("brightness") ?: 0.5
                        val lp = window.attributes
                        lp.screenBrightness = level.toFloat().coerceIn(0.01f, 1.0f)
                        window.attributes = lp
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BRIGHTNESS_ERROR", e.localizedMessage, null)
                    }
                }
                "getVolume" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val cur = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                        val v = if (max > 0) cur.toDouble() / max.toDouble() else 0.5
                        result.success(v)
                    } catch (e: Exception) {
                        result.error("VOLUME_ERROR", e.localizedMessage, null)
                    }
                }
                "setVolume" -> {
                    try {
                        val level = call.argument<Double>("volume") ?: 0.5
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val target = (level * max).roundToInt().coerceIn(0, max)
                        // Flag 0 suppresses the OS system volume dialog to allow custom HUD indicator
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("VOLUME_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

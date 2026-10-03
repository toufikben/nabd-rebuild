package com.nabd.journal

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A private journal: keep its pages out of screenshots, screen
        // recordings and the Recents thumbnail.
        if (!screenshotsAllowedForTesting()) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }

    /**
     * Device testing needs `adb screencap`, which FLAG_SECURE turns black.
     * Only a debuggable build honours `adb shell setprop
     * debug.nabd.screenshots 1`; release builds are always protected.
     */
    private fun screenshotsAllowedForTesting(): Boolean {
        val debuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!debuggable) return false
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("getprop", "debug.nabd.screenshots"))
            process.inputStream.bufferedReader().readText().trim() == "1"
        } catch (e: Exception) {
            false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nabd/widget")
            .setMethodCallHandler { call, result ->
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                getSharedPreferences(JournalWidgetProvider.PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .putString("title", call.argument<String>("title"))
                    .putString("streak", call.argument<String>("streak"))
                    .putString("prompt", call.argument<String>("prompt"))
                    .apply()
                JournalWidgetProvider.refreshAll(applicationContext)
                result.success(null)
            }
    }
}

package com.nabd.journal

import android.content.Context
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
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
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

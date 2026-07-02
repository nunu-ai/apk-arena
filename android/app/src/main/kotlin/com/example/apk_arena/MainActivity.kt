package com.example.apk_arena

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "apkarena/links"
    private var linkChannel: MethodChannel? = null
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        linkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        linkChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(initialLink)
                    initialLink = null
                }
                else -> result.notImplemented()
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val data: Uri? = intent?.data
        val uriString = data?.toString()
        android.util.Log.d("APKARENA", "handleIntent data=$uriString")
        if (uriString == null) return
        initialLink = uriString
        if (linkChannel != null) {
            try {
                // Deliver immediately to Dart when it is ready. The retained
                // initial link is cleared by getInitialLink and de-duped in Dart.
                linkChannel!!.invokeMethod("onLink", uriString)
                return
            } catch (_: Exception) {
                return
            }
        }
    }
}

package com.example.uniflow_front

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uniflow/android_widgets",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncWidgets" -> {
                    val payload = call.argument<String>("payload")
                    if (payload.isNullOrBlank()) {
                        result.error("missing_payload", "Widget payload is empty", null)
                        return@setMethodCallHandler
                    }

                    UniFlowWidgetRepository.savePayload(applicationContext, payload)
                    UniFlowWidgetUpdater.updateAll(applicationContext)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}

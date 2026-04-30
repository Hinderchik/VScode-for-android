package com.vscode.android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vscode.android/tor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTor" -> {
                    val intent = android.content.Intent("org.torproject.android.intent.action.START")
                    intent.setPackage("org.torproject.android")
                    sendBroadcast(intent)
                    result.success(true)
                }
                "stopTor" -> {
                    val intent = android.content.Intent("org.torproject.android.intent.action.STOP")
                    intent.setPackage("org.torproject.android")
                    sendBroadcast(intent)
                    result.success(true)
                }
                "isRunning" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }
}

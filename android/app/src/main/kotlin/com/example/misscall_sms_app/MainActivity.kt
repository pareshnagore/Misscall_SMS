package com.example.misscall_sms_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.SharedPreferences

class MainActivity : FlutterActivity() {
	private val CHANNEL = "misscall_sms/sms_log"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "getSmsLog") {
				val prefs: SharedPreferences = applicationContext.getSharedPreferences("missed_call_sms", Context.MODE_PRIVATE)
				val logJson = prefs.getString("sms_sent_log", "[]")
				result.success(logJson)
			} else {
				result.notImplemented()
			}
		}
	}
}

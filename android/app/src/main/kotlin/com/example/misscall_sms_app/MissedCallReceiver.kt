package com.example.misscall_sms_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

class MissedCallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        if (state == TelephonyManager.EXTRA_STATE_IDLE) {
            // Phone stopped ringing, possible missed call
                // Add a 5-second delay before querying the call log
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                val cursor = context.contentResolver.query(
                    android.provider.CallLog.Calls.CONTENT_URI,
                    null,
                    null,
                    null,
                    "${android.provider.CallLog.Calls.DATE} DESC"
                )
                var number: String? = null
                var timestamp: Long? = null
                cursor?.use {
                    if (it.moveToFirst() && it.getInt(it.getColumnIndexOrThrow(android.provider.CallLog.Calls.TYPE)) == android.provider.CallLog.Calls.MISSED_TYPE) {
                        number = it.getString(it.getColumnIndexOrThrow(android.provider.CallLog.Calls.NUMBER))
                        timestamp = it.getLong(it.getColumnIndexOrThrow(android.provider.CallLog.Calls.DATE))
                    }
                }
                if (number != null && timestamp != null) {
                    val serviceIntent = Intent(context, SmsSenderService::class.java)
                    serviceIntent.putExtra("missed_number", number)
                    serviceIntent.putExtra("missed_timestamp", timestamp)
                    context.startService(serviceIntent)
                }
                }, 5000)
        }
    }
}

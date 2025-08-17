package com.example.misscall_sms_app

import android.app.IntentService
import android.content.Intent
import android.telephony.SmsManager
import android.provider.CallLog
import android.content.Context
import android.content.SharedPreferences

class SmsSenderService : IntentService("SmsSenderService") {

    override fun onHandleIntent(intent: Intent?) {
        val missedCall = getLastMissedCallInfo()
        if (missedCall != null) {
            val (number, timestamp) = missedCall
            // Use a separate SharedPreferences for tracking handled calls
            val appPrefs: SharedPreferences = getSharedPreferences("missed_call_sms", Context.MODE_PRIVATE)
            val lastHandledNumber = appPrefs.getString("last_handled_number", null)
            val lastHandledTimestamp = appPrefs.getLong("last_handled_timestamp", -1L)

            if (number != lastHandledNumber || timestamp != lastHandledTimestamp) {
                // Read SMS text from Flutter's SharedPreferences
                val sharedPrefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val smsText = sharedPrefs.getString("flutter.sms_text", "Hello! Messege me with purpose of your call and I will get back to you.")!!

                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(
                    number,
                    null,
                    smsText,
                    null,
                    null
                )

                // Save this missed call as handled
                appPrefs.edit()
                    .putString("last_handled_number", number)
                    .putLong("last_handled_timestamp", timestamp)
                    .apply()
            }
        }
    }

    private fun getLastMissedCallInfo(): Pair<String, Long>? {
        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null,
            null,
            null,
            "${CallLog.Calls.DATE} DESC"
        )
        cursor?.use {
            if (it.moveToFirst() && it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE)) == CallLog.Calls.MISSED_TYPE) {
                val number = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                val timestamp = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                return Pair(number, timestamp)
            }
        }
        return null
    }
}

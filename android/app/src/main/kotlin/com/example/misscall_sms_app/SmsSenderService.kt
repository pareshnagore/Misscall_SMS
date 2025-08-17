package com.example.misscall_sms_app

import android.app.IntentService
import android.content.Intent
import android.telephony.SmsManager
import android.provider.CallLog
import android.content.Context
import android.content.SharedPreferences

class SmsSenderService : IntentService("SmsSenderService") {

    override fun onHandleIntent(intent: Intent?) {
            val lastCallNumber = getLastMissedCallNumber()
            if (!lastCallNumber.isNullOrEmpty()) {
                // Read SMS text from Flutter's SharedPreferences
                val sharedPrefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val smsText = sharedPrefs.getString("flutter.sms_text", "Hello! Messege me with purpose of your call and I will get back to you.")!!

                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(
                    lastCallNumber,
                    null,
                    smsText,
                    null,
                    null
                )
            }
    }

    private fun getLastMissedCallNumber(): String? {
        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null,
            null,
            null,
            "${CallLog.Calls.DATE} DESC"
        )
        cursor?.use {
            if (it.moveToFirst() && it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE)) == CallLog.Calls.MISSED_TYPE) {
                return it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
            }
        }
        return null
    }
}

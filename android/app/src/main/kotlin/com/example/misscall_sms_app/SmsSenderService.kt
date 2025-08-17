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

            if ((number != lastHandledNumber || timestamp != lastHandledTimestamp) && isUnknownNumber(number)) {
                // Read SMS text from Flutter's SharedPreferences
                val sharedPrefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val smsText = sharedPrefs.getString("flutter.sms_text", "Hello! Messege me with purpose of your call and I will get back to you.")!!

                val smsManager = SmsManager.getDefault()
                var smsStatus = "success"
                try {
                    smsManager.sendTextMessage(
                        number,
                        null,
                        smsText,
                        null,
                        null
                    )
                } catch (e: Exception) {
                    smsStatus = "failure"
                }

                // Save this missed call as handled
                appPrefs.edit()
                    .putString("last_handled_number", number)
                    .putLong("last_handled_timestamp", timestamp)
                    .apply()

                // Log the SMS event (number, timestamp, status) in SharedPreferences as JSON array
                val logKey = "sms_sent_log"
                val logJson = appPrefs.getString(logKey, "[]")
                val logArray = org.json.JSONArray(logJson)
                val logEntry = org.json.JSONObject()
                logEntry.put("number", number)
                logEntry.put("timestamp", timestamp)
                logEntry.put("status", smsStatus)
                logArray.put(logEntry)
                appPrefs.edit().putString(logKey, logArray.toString()).apply()
            }
        }
    }

    // Returns true if the number is NOT in contacts
    private fun isUnknownNumber(number: String): Boolean {
        val uri = android.provider.ContactsContract.PhoneLookup.CONTENT_FILTER_URI.buildUpon()
            .appendPath(number)
            .build()
        val cursor = contentResolver.query(
            uri,
            arrayOf(android.provider.ContactsContract.PhoneLookup._ID),
            null,
            null,
            null
        )
        val isUnknown = cursor == null || !cursor.moveToFirst()
        cursor?.close()
        return isUnknown
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

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
            val serviceIntent = Intent(context, SmsSenderService::class.java)
            serviceIntent.putExtras(intent.extras ?: android.os.Bundle())
            context.startService(serviceIntent)
        }
    }
}

// MyApplication.kt
package com.transistorsoft.bggeo.kotlin.demo

import android.app.Application
import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.lifecycle.LifecycleManager
import java.io.File

class Application : Application() {
    companion object {
        private const val TAG = "TSLocationManager"
    }

    override fun onCreate() {
        super.onCreate()

        // Initialize BGGeo Kotlin API
        BGGeo.init(this)

        // DEBUG:  Disable TerminateEvent oneshot during FGS relaunch testing.
        LifecycleManager.setDisableTerminateEventOneShot(false)

        Log.d(TAG, "***********************************************")
        Log.d(TAG, "* MainApplication onCreate - START")
        Log.d(TAG, "***********************************************")

        Log.d(TAG, "***********************************************")
        Log.d(TAG, "* MainApplication onCreate - END")
        Log.d(TAG, "***********************************************")
    }
}

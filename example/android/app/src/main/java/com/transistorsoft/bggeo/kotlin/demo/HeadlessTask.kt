package com.transistorsoft.locationmanager.demo

import android.util.Log
import com.transistorsoft.locationmanager.adapter.BackgroundGeolocation
import com.transistorsoft.locationmanager.event.EventName
import com.transistorsoft.locationmanager.event.HeadlessEvent
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode

@Suppress("unused")
class HeadlessTask {

    companion object {
        private var sGeofenceCounter: Int = 0

        @Synchronized
        private fun nextGeofenceIdentifier(): String {
            sGeofenceCounter += 1
            return "headless-geofence-test-$sGeofenceCounter"
        }
    }

    private fun simulateHeavyCpuWork(durationMs: Long) {
        val startTime = System.currentTimeMillis()
        var result = 0

        Log.d("TSLocationManager", "- startWork(${durationMs}ms)")
        while (System.currentTimeMillis() - startTime < durationMs) {
            // Burn CPU cycles
            result += (Math.random() * 1000).toInt()
        }
        Log.d("TSLocationManager", "- endWork")
    }

    @Subscribe(threadMode = ThreadMode.ASYNC)
    fun onHeadlessEvent(event: HeadlessEvent) {
        Log.d("TSLocationManager", "💀 👍 HeadlessTask.kt onHeadlessEvent: " + event.name + ", " + event.event)
        val bgGeo = BackgroundGeolocation.getInstance(event.context);
        //simulateHeavyCpuWork(250)
        /*

        bgGeo.startBackgroundTask(object: TSBackgroundTaskCallback {
            override fun onStart(taskId: Int) {
                Log.d(BackgroundGeolocation.TAG, "- do headless work");
                simulateHeavyCpuWork(20)
                bgGeo.stopBackgroundTask(taskId)
            }
            override fun onCancel(taskId: Int) {
                bgGeo.stopBackgroundTask(taskId)
            }
        });
        */

        when (event.name) {  // calls getName()
            EventName.BOOT -> {
                // JSONObject
                val boot = event.bootEvent
                // TODO handle boot
            }

            EventName.TERMINATE -> {
                // JSONObject
                val terminate = event.terminateEvent
                // TODO handle terminate
            }

            EventName.LOCATION -> {
                // LocationEvent
                val locationEvent = event.locationEvent
                // TODO handle location
            }

            EventName.LOCATION_ERROR -> {
                // NOTE: HeadlessEvent does NOT expose a typed getter for LOCATION_ERROR.
                // Use raw payload and cast as appropriate for your SDK.
                val payload = event.event
                // TODO handle location_error
            }

            EventName.MOTIONCHANGE -> {
                val motionChange = event.motionChangeEvent
                // TODO handle motionchange
            }

            EventName.GEOFENCE -> {
                Log.d("TSLocationManager", "*** 💀CREATE NEW GEOFENCE")

                val geofenceEvent = event.geofenceEvent
                // TODO handle geofence

                /* DISABLED TEST CODE
                var json = JSONObject()
                json.put("headless-geofence", true)

                val geofence = TSGeofence.Builder()
                    .setLatitude(geofenceEvent.location.latitude)
                    .setLongitude(geofenceEvent.location.longitude)
                    .setNotifyOnEntry(false)
                    .setNotifyOnExit(true)
                    .setExtras(json)
                    .setIdentifier(nextGeofenceIdentifier())
                    .build()
                bgGeo.addGeofence(geofence)
                */
            }

            EventName.GEOFENCESCHANGE -> {
                val geofencesChange = event.geofencesChangeEvent
                // TODO handle geofenceschange
            }

            EventName.ACTIVITYCHANGE -> {
                val activityChange = event.activityChangeEvent
                // TODO handle activitychange
            }

            EventName.HEARTBEAT -> {
                val heartbeat = event.heartbeatEvent
                // TODO handle heartbeat
            }

            EventName.HTTP -> {
                val http = event.httpEvent
                // TODO handle http
            }

            EventName.SCHEDULE -> {
                // JSONObject
                val schedule = event.scheduleEvent
                // TODO handle schedule
            }

            EventName.PROVIDERCHANGE -> {
                val provider = event.providerChangeEvent
                // TODO handle providerchange
            }

            EventName.POWERSAVECHANGE -> {
                val powerSave = event.powerSaveChangeEvent
                // TODO handle powersavechange
            }

            EventName.CONNECTIVITYCHANGE -> {
                val connectivity = event.connectivityChangeEvent
                // TODO handle connectivitychange
            }

            EventName.ENABLEDCHANGE -> {
                val enabled = event.enabledChangeEvent
                // TODO handle enabledchange
            }

            EventName.AUTHORIZATION -> {
                val authorization = event.authorizationEvent
                // TODO handle authorization
            }

            EventName.NOTIFICATIONACTION -> {
                val action = event.notificationEvent
                // TODO handle notificationaction
            }

            else -> {
                // Fallback: raw payload
                val payload = event.event
                // TODO handle unknown headless event
            }
        }
    }
}
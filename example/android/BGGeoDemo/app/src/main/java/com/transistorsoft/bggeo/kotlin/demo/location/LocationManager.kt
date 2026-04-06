package com.transistorsoft.bggeo.kotlin.demo.location

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.appcompat.app.AlertDialog
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.TransistorAuthorizationService
import com.transistorsoft.locationmanager.kotlin.EventSubscription
import com.transistorsoft.locationmanager.kotlin.config.DesiredAccuracy
import com.transistorsoft.locationmanager.kotlin.config.LogLevel
import com.transistorsoft.locationmanager.kotlin.config.TrackingMode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

import android.widget.EditText
import android.text.InputType
import com.transistorsoft.locationmanager.demo.HeadlessTask

const val TRACKER_HOST = "https://bg-console-staging.herokuapp.com"

/**
 * Manages location tracking state and operations.
 * Centralizes all BGGeo logic and provides clean state management.
 */
class LocationManager(
    private val activity: Activity,
    private val bgGeo: BGGeo,
    private val lifecycleScope: CoroutineScope
) {
    companion object {
        private var sGeofenceCounter: Int = 0
        private const val TAG = "LocationManager"

        // Transistor Authorization preference keys (shared with SettingsBottomSheet)
        const val PREFS_NAME = "transistor_auth"
        const val KEY_ORG = "tracker.transistorsoft.com:org"
        const val KEY_USERNAME = "tracker.transistorsoft.com:username"

        @Synchronized
        private fun nextGeofenceIdentifier(): String {
            sGeofenceCounter += 1
            return "foreground-geofence-test-$sGeofenceCounter"
        }
    }

    // Location tracking state
    data class TrackingState(
        val isTracking: Boolean = false,
        val isMoving: Boolean = false,
        val isEnabled: Boolean = true
    )

    private val _trackingState = MutableLiveData(TrackingState())
    val trackingState: LiveData<TrackingState> = _trackingState

    private val _odometerMeters = MutableLiveData(0.0)
    val odometerMeters: LiveData<Double> = _odometerMeters

    private val _odometerErrorMeters = MutableLiveData(0.0)
    val odometerErrorMeters: LiveData<Double> = _odometerErrorMeters

    private val _needsRegistration = MutableLiveData(false)
    val needsRegistration: LiveData<Boolean> = _needsRegistration

    private val subscriptions = mutableSetOf<EventSubscription>()

    init {
        setupLocationCallbacks()
    }

    /**
     * Initialize the location manager with authentication and default config.
     * Posts needsRegistration=true and returns early if org/username are not set.
     */
    fun initialize() {
        val prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val org = prefs.getString(KEY_ORG, "") ?: ""
        val username = prefs.getString(KEY_USERNAME, "") ?: ""

        if (org.isEmpty() || username.isEmpty()) {
            _needsRegistration.value = true
            return
        }

        lifecycleScope.launch {
            var token: com.transistorsoft.locationmanager.kotlin.TransistorToken? = null
            try {
                token = TransistorAuthorizationService.findOrCreateToken(
                    context = activity.applicationContext,
                    org = org,
                    username = username,
                    url = TRACKER_HOST
                )
                Log.d(TAG, "Authentication token obtained: ${token.accessToken.take(6)}...")
            } catch (e: Exception) {
                Log.e(TAG, "Authentication failed: ${e.message}")
            }

            callReady(token)
        }
    }

    /**
     * Called after first-launch registration to finish SDK initialisation.
     */
    fun completeInitialRegistration(org: String, username: String) {
        val prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_ORG, org).putString(KEY_USERNAME, username).apply()

        lifecycleScope.launch {
            var token: com.transistorsoft.locationmanager.kotlin.TransistorToken? = null
            try {
                TransistorAuthorizationService.destroyToken(activity.applicationContext, TRACKER_HOST)
                token = TransistorAuthorizationService.findOrCreateToken(
                    context = activity.applicationContext,
                    org = org,
                    username = username,
                    url = TRACKER_HOST
                )
                Log.d(TAG, "Initial registration token: ${token.accessToken.take(6)}...")
            } catch (e: Exception) {
                Log.e(TAG, "Initial registration failed: ${e.message}")
            }

            callReady(token)
            _needsRegistration.postValue(false)
        }
    }

    private suspend fun callReady(token: com.transistorsoft.locationmanager.kotlin.TransistorToken?) {
        try {
            // reset=false: config closure only runs on first install.
            // Subsequent launches use persisted config (e.g., from Settings UI).
            // token: auto-configures http.url + authorization for demo server.
            bgGeo.ready(reset = false, transistorAuthorizationToken = token) {
                logger.debug = true
                logger.logLevel = LogLevel.VERBOSE
                logger.logMaxDays = 3
                app.stopOnTerminate = false
                app.startOnBoot = true
                app.serviceLaunchDelay = 1000
                app.heartbeatInterval = 60.0
                app.enableHeadless = true
                app.headlessJobService = HeadlessTask::class.java.name
                geolocation.desiredAccuracy = DesiredAccuracy.HIGH
                geolocation.distanceFilter = 50.0f
                geolocation.geofenceInitialTriggerEntry = true
                persistence.maxDaysToPersist = 7
                app.notification.smallIcon = "drawable/ic_service_icon"
                app.notification.largeIcon = "drawable/ic_service_icon"
                app.notification.title = "NOTI TITLE"
                app.notification.color = "FF0000"
                app.notification.text = "NOTI TEXT"
            }
            Log.d(TAG, "BackgroundGeolocation ready")
            syncStateWithSDK()
        } catch (e: Exception) {
            Log.e(TAG, "BackgroundGeolocation ready failed: ${e.message}")
        }
    }

    private fun setupLocationCallbacks() {
        bgGeo.onEnabledChange { event ->
            Log.d(TAG, "Tracking enabled changed: ${event.enabled}")
            updateTrackingState(
                isTracking = event.enabled,
                isMoving = if (event.enabled) _trackingState.value?.isMoving ?: false else false
            )
        }.storeIn(subscriptions)

        bgGeo.onLocation { event ->
            _odometerMeters.postValue(event.odometer)
            _odometerErrorMeters.postValue(event.odometerError)
            Log.d(TAG, "onLocation")
        }.storeIn(subscriptions)

        bgGeo.onMotionChange { event ->
            Log.d(TAG, "onMotionChange: isMoving=${event.isMoving}")
            updateTrackingState(isMoving = event.isMoving)
        }.storeIn(subscriptions)

        bgGeo.onGeofence { event ->
            Log.d(TAG, "onGeofence: ${event.toJson()}")
        }.storeIn(subscriptions)

        bgGeo.onGeofencesChange { event ->
            Log.d(TAG, "onGeofencesChange: $event")
        }.storeIn(subscriptions)

        bgGeo.onProviderChange { event ->
            Log.d(TAG, "onProviderChange: $event")
        }.storeIn(subscriptions)

        bgGeo.onActivityChange { event ->
            Log.d(TAG, "onActivityChange: $event")
        }.storeIn(subscriptions)

        bgGeo.onConnectivityChange { event ->
            Log.d(TAG, "onConnectivityChange: ${event.isConnected}")
        }.storeIn(subscriptions)
    }

    private fun syncStateWithSDK() {
        val config = bgGeo.config
        updateTrackingState(
            isTracking = config.enabled,
            isMoving = config.isMoving
        )
    }

    private fun updateTrackingState(
        isTracking: Boolean? = null,
        isMoving: Boolean? = null,
        isEnabled: Boolean? = null
    ) {
        val current = _trackingState.value ?: TrackingState()
        _trackingState.value = current.copy(
            isTracking = isTracking ?: current.isTracking,
            isMoving = isMoving ?: current.isMoving,
            isEnabled = isEnabled ?: current.isEnabled
        )
    }

    /**
     * Start location tracking
     */
    fun startTracking() {
        updateTrackingState(isEnabled = false)

        lifecycleScope.launch {
            try {
                val config = bgGeo.config
                if (config.trackingMode == TrackingMode.LOCATION) {
                    bgGeo.start()
                } else {
                    bgGeo.startGeofences()
                }
                Log.d(TAG, "Location tracking started successfully")
                updateTrackingState(isTracking = true, isEnabled = true)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start location tracking: ${e.message}")
                updateTrackingState(isTracking = false, isEnabled = true)
            }
        }
    }

    /**
     * Stop location tracking
     */
    fun stopTracking() {
        updateTrackingState(isEnabled = false)

        lifecycleScope.launch {
            try {
                bgGeo.stop()
                Log.d(TAG, "Location tracking stopped successfully")
                updateTrackingState(isTracking = false, isEnabled = true)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop location tracking: ${e.message}")
                updateTrackingState(isTracking = true, isEnabled = true)
            }
        }
    }

    /**
     * Change movement pace (moving/stationary)
     */
    fun changePace(isMoving: Boolean) {
        bgGeo.changePace(isMoving)
        updateTrackingState(isMoving = isMoving)
        Log.d(TAG, "Pace changed to: ${if (isMoving) "moving" else "stationary"}")
    }

    /**
     * Get current position
     */
    fun getCurrentPosition() {
        lifecycleScope.launch {
            try {
                val extras = mapOf("getCurrentPosition" to true)
                val event = bgGeo.getCurrentPosition(
                    samples = 3,
                    persist = true,
                    desiredAccuracy = 100.0,
                    maximumAge = 5000,
                    extras = extras
                )
                Log.d(TAG, "Current position obtained: ${event.toMap()}")
            } catch (e: Exception) {
                Log.e(TAG, "Current position error: ${e.message}")
            }
        }
    }

    /**
     * Sync locations to server
     */
    fun sync() {
        val count = bgGeo.store.count
        if (count == 0) {
            AlertDialog.Builder(activity)
                .setTitle("Upload Locations")
                .setMessage("Database is empty")
                .setPositiveButton("Ok", null)
                .show()
            return
        }
        AlertDialog.Builder(activity)
            .setTitle("Upload Locations")
            .setMessage("Upload $count locations?")
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Ok") { _, _ ->
                lifecycleScope.launch {
                    try {
                        val records = bgGeo.store.sync()
                        Log.d(TAG, "Sync completed: $records")
                    } catch (e: Exception) {
                        Log.e(TAG, "Sync failed: ${e.message}")
                    }
                }
            }
            .show()
    }

    /**
     * Destroy stored locations
     */
    fun destroyLocations() {
        val count = bgGeo.store.count
        if (count == 0) {
            AlertDialog.Builder(activity)
                .setTitle("Destroy Locations")
                .setMessage("Database is empty")
                .setPositiveButton("Ok", null)
                .show()
            return
        }
        AlertDialog.Builder(activity)
            .setTitle("Destroy Locations")
            .setMessage("Destroy $count locations?")
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Ok") { _, _ ->
                bgGeo.store.destroyAll()
                Log.d(TAG, "Destroyed $count locations")
            }
            .show()
    }

    /**
     * Reset odometer
     */
    fun resetOdometer() {
        lifecycleScope.launch {
            try {
                val event = bgGeo.setOdometer(0.0)
                Log.d(TAG, "Odometer reset successfully: ${event.location}")
                _odometerMeters.value = 0.0
            } catch (e: Exception) {
                Log.e(TAG, "Odometer reset failed: ${e.message}")
            }
        }
    }

    /**
     * Toggle watchPosition ON/OFF.
     */
    private var watchPositionSubscription: EventSubscription? = null

    fun watchPosition() {
        watchPositionSubscription?.let {
            it.close()
            watchPositionSubscription = null
            Log.d(TAG, "watchPosition: OFF")
            return
        }

        watchPositionSubscription = bgGeo.watchPosition(
            persist = true,
            interval = 1000,
            success = { event ->
                Log.d(TAG, "watchPosition location: ${event.toMap()}")
            },
            failure = { errorCode ->
                Log.e(TAG, "watchPosition error: $errorCode")
            }
        )
        Log.d(TAG, "watchPosition: ON")
    }

    /**
     * Request location permissions
     */
    fun requestPermission() {
        lifecycleScope.launch {
            bgGeo.authorization.requestPermission()
        }
    }

    /**
     * Email debug log
     */
    fun emailLog() {
        val prefs = activity.getSharedPreferences("demo_prefs", Context.MODE_PRIVATE)
        val existing = prefs.getString("email_log_address", null)

        val input = EditText(activity).apply {
            hint = "Email address"
            setText(existing ?: "")
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS
            setSingleLine(true)
            setSelection(text?.length ?: 0)
        }

        val builder = AlertDialog.Builder(activity)
            .setTitle("Email Log")
            .setView(input)

        if (existing != null) {
            builder.setMessage("Send logs to this address?")
        }

        builder
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Ok") { _, _ ->
                val email = input.text?.toString()?.trim().orEmpty()
                if (email.isNotEmpty()) {
                    prefs.edit().putString("email_log_address", email).apply()
                    lifecycleScope.launch {
                        try {
                            bgGeo.logger.emailLog(email, activity)
                            Log.d(TAG, "Email log intent launched for $email")
                        } catch (e: Exception) {
                            Log.e(TAG, "Email log failed: ${e.message}")
                        }
                    }
                } else {
                    AlertDialog.Builder(activity)
                        .setTitle("Email Log")
                        .setMessage("Please enter an email address")
                        .setPositiveButton("Ok", null)
                        .show()
                }
            }
            .show()
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        subscriptions.forEach { it.close() }
        subscriptions.clear()
        Log.d(TAG, "LocationManager cleanup completed")
    }
}

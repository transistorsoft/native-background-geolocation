package com.transistorsoft.tslocationmanager.demo.settings

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.config.Config
import com.transistorsoft.locationmanager.kotlin.config.ConfigEditor
import com.transistorsoft.locationmanager.kotlin.config.DesiredAccuracy
import com.transistorsoft.locationmanager.kotlin.config.LocationAuthorizationRequest
import com.transistorsoft.locationmanager.kotlin.config.LogLevel
import com.transistorsoft.locationmanager.kotlin.config.PersistMode
import com.transistorsoft.locationmanager.kotlin.config.TrackingMode
import kotlinx.coroutines.launch
import com.transistorsoft.tslocationmanager.demo.UiConfigState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * ViewModel for managing TSConfig state with batched editing support.
 *
 * Usage:
 * 1. Read current state from `snapshot`
 * 2. Stage changes using setter methods (auto-begins edit session)
 * 3. Call `persistAndApply()` to commit, or `cancel()` to discard
 */
class ConfigViewModel(app: Application) : AndroidViewModel(app) {

    companion object {
        private const val TAG = "ConfigViewModel"
    }

    // --- Organized Data Classes ---

    data class GeolocationConfig(
        val desiredAccuracy: DesiredAccuracy,
        val distanceFilter: Float,
        val locationUpdateInterval: Long,
        val fastestLocationUpdateInterval: Long,
        val stationaryRadius: Int,
        val stopTimeout: Long,
        val geofenceProximityRadius: Long,
        val locationAuthorizationRequest: LocationAuthorizationRequest,
        val significantChangesOnly: Boolean,
        val geofenceModeHighAccuracy: Boolean,
        val disableElasticity: Boolean
    )

    data class MotionConfig(
        val stopDetectionDelayMs: Int,
        val disableMotionActivityUpdates: Boolean,
        val disableStopDetection: Boolean
    )

    data class HttpConfig(
        val url: String,
        val autoSync: Boolean,
        val autoSyncThreshold: Int,
        val batchSync: Boolean,
        val maxBatchSize: Int
    )

    data class PersistenceConfig(
        val maxRecordsToPersist: Int,
        val maxDaysToPersist: Int,
        val persistMode: PersistMode
    )

    data class ApplicationConfig(
        val stopOnTerminate: Boolean,
        val startOnBoot: Boolean,
        val heartbeatInterval: Double
    )

    data class DebugConfig(
        val debug: Boolean,
        val logLevel: LogLevel,
        val logMaxDays: Int
    )

    data class Snapshot(
        val geolocation: GeolocationConfig,
        val motion: MotionConfig,
        val http: HttpConfig,
        val persistence: PersistenceConfig,
        val application: ApplicationConfig,
        val logger: DebugConfig
    ) {
        // Backwards compatibility - flat property access for existing UI code
        val desiredAccuracy get() = geolocation.desiredAccuracy
        val distanceFilter get() = geolocation.distanceFilter
        val locationUpdateInterval get() = geolocation.locationUpdateInterval
        val fastestLocationUpdateInterval get() = geolocation.fastestLocationUpdateInterval
        val stationaryRadius get() = geolocation.stationaryRadius
        val stopTimeout get() = geolocation.stopTimeout
        val geofenceProximityRadius get() = geolocation.geofenceProximityRadius
        val locationAuthorizationRequest get() = geolocation.locationAuthorizationRequest
        val significantChangesOnly get() = geolocation.significantChangesOnly
        val geofenceModeHighAccuracy get() = geolocation.geofenceModeHighAccuracy
        val disableElasticity get() = geolocation.disableElasticity

        val stopDetectionDelayMs get() = motion.stopDetectionDelayMs
        val disableMotionActivityUpdates get() = motion.disableMotionActivityUpdates
        val disableStopDetection get() = motion.disableStopDetection

        val url get() = http.url
        val autoSync get() = http.autoSync
        val autoSyncThreshold get() = http.autoSyncThreshold
        val batchSync get() = http.batchSync
        val maxBatchSize get() = http.maxBatchSize

        val maxRecordsToPersist get() = persistence.maxRecordsToPersist
        val maxDaysToPersist get() = persistence.maxDaysToPersist
        val persistMode get() = persistence.persistMode

        val stopOnTerminate get() = application.stopOnTerminate
        val startOnBoot get() = application.startOnBoot
        val heartbeatInterval get() = application.heartbeatInterval

        val debug get() = logger.debug
        val logLevel get() = logger.logLevel
        val logMaxDays get() = logger.logMaxDays
    }

    // --- State Management ---

    private val bgGeo: BGGeo = BGGeo.instance

    private val _snapshot = MutableStateFlow(buildSnapshot())
    val snapshot: StateFlow<Snapshot> = _snapshot.asStateFlow()

    // --- Staging ---
    private var pendingActions = mutableListOf<ConfigEditor.() -> Unit>()
    private var pendingTrackingMode: TrackingMode? = null

    init {
        logDebug("Initialized with snapshot")
    }

    // --- Public API ---

    fun begin() {
        logDebug("Started edit session")
    }

    fun cancel() {
        pendingActions.clear()
        pendingTrackingMode = null
        refreshSnapshot()
        logDebug("Cancelled edit session, discarded pending edits")
    }

    fun persistAndApply() {
        logDebug("Persisting and applying changes")

        if (pendingActions.isNotEmpty()) {
            bgGeo.config.edit {
                pendingActions.forEach { action -> action() }
            }
            pendingActions.clear()
            logDebug("Committed editor changes")
        }

        pendingTrackingMode?.let { mode ->
            logDebug("Applied tracking mode: $mode")
            viewModelScope.launch {
                try {
                    if (mode == TrackingMode.LOCATION) {
                        bgGeo.start()
                    } else {
                        bgGeo.startGeofences()
                    }
                } catch (_: Exception) {}
            }
        }

        pendingTrackingMode = null
        refreshSnapshot()
        logDebug("Persist and apply completed")
    }

    // --- Geolocation Setters ---

    fun setDesiredAccuracy(value: DesiredAccuracy) = stage {
        geolocation.desiredAccuracy = value
        logDebug("Staged desiredAccuracy: $value")
    }

    fun setDistanceFilter(value: Float) = stage {
        geolocation.distanceFilter = value
        logDebug("Staged distanceFilter: $value")
    }

    fun setLocationUpdateInterval(value: Int) = stage {
        geolocation.locationUpdateInterval = value.toLong()
        logDebug("Staged locationUpdateInterval: $value")
    }

    fun setFastestLocationUpdateInterval(value: Int) = stage {
        geolocation.fastestLocationUpdateInterval = value.toLong()
        logDebug("Staged fastestLocationUpdateInterval: $value")
    }

    fun setStationaryRadius(value: Float) = stage {
        geolocation.stationaryRadius = value.toInt()
        logDebug("Staged stationaryRadius: $value")
    }

    fun setStopTimeout(value: Int) = stage {
        geolocation.stopTimeout = value.toLong()
        logDebug("Staged stopTimeout: $value")
    }

    fun setGeofenceProximityRadius(value: Int) = stage {
        geolocation.geofenceProximityRadius = value.toLong()
        logDebug("Staged geofenceProximityRadius: $value")
    }

    fun setLocationAuthorizationRequest(value: LocationAuthorizationRequest) = stage {
        geolocation.locationAuthorizationRequest = value
        logDebug("Staged locationAuthorizationRequest: $value")
    }

    fun setAuthorization(value: LocationAuthorizationRequest) = setLocationAuthorizationRequest(value)

    fun setUseSignificantChangesOnly(value: Boolean) = stage {
        geolocation.useSignificantChangesOnly = value
        logDebug("Staged useSignificantChangesOnly: $value")
    }

    fun setGeofenceModeHighAccuracy(value: Boolean) = stage {
        geolocation.geofenceModeHighAccuracy = value
        logDebug("Staged geofenceModeHighAccuracy: $value")
    }

    fun setDisableElasticity(value: Boolean) = stage {
        geolocation.disableElasticity = value
        logDebug("Staged disableElasticity: $value")
    }

    fun setTrackingMode(mode: UiConfigState.TrackingMode) {
        pendingTrackingMode = when (mode) {
            UiConfigState.TrackingMode.LOCATION_AND_GEOFENCES -> TrackingMode.LOCATION
            UiConfigState.TrackingMode.GEOFENCES_ONLY -> TrackingMode.GEOFENCE
        }
        logDebug("Staged tracking mode: $pendingTrackingMode")
    }

    // --- Motion Setters ---

    fun setStopDetectionDelayMs(value: Long) = stage {
        activity.motionTriggerDelay = value.toInt()
        logDebug("Staged stopDetectionDelayMs: $value")
    }

    fun setDisableMotionActivityUpdates(value: Boolean) = stage {
        activity.disableMotionActivityUpdates = value
        logDebug("Staged disableMotionActivityUpdates: $value")
    }

    fun setDisableStopDetection(value: Boolean) = stage {
        activity.disableStopDetection = value
        logDebug("Staged disableStopDetection: $value")
    }

    // --- HTTP Setters ---

    fun setUrl(value: String) = stage {
        http.url = value
        logDebug("Staged url: $value")
    }

    fun setAutoSync(value: Boolean) = stage {
        http.autoSync = value
        logDebug("Staged autoSync: $value")
    }

    fun setAutoSyncThreshold(value: Int) = stage {
        http.autoSyncThreshold = value
        logDebug("Staged autoSyncThreshold: $value")
    }

    fun setBatchSync(value: Boolean) = stage {
        http.batchSync = value
        logDebug("Staged batchSync: $value")
    }

    fun setMaxBatchSize(value: Int) = stage {
        http.maxBatchSize = value
        logDebug("Staged maxBatchSize: $value")
    }

    // --- Persistence Setters ---

    fun setMaxRecordsToPersist(value: Int) = stage {
        persistence.maxRecordsToPersist = value
        logDebug("Staged maxRecordsToPersist: $value")
    }

    fun setMaxDaysToPersist(value: Int) = stage {
        persistence.maxDaysToPersist = value
        logDebug("Staged maxDaysToPersist: $value")
    }

    fun setPersistMode(value: PersistMode) = stage {
        persistence.persistMode = value
        logDebug("Staged persistMode: $value")
    }

    // --- Application Setters ---

    fun setStopOnTerminate(value: Boolean) = stage {
        app.stopOnTerminate = value
        logDebug("Staged stopOnTerminate: $value")
    }

    fun setStartOnBoot(value: Boolean) = stage {
        app.startOnBoot = value
        logDebug("Staged startOnBoot: $value")
    }

    fun setHeartbeatInterval(value: Int) = stage {
        app.setHeartbeatInterval(value)
        logDebug("Staged heartbeatInterval: $value")
    }

    // --- Debug Setters ---

    fun setDebug(value: Boolean) = stage {
        logger.debug = value
        logDebug("Staged debug: $value")
    }

    fun setLogLevel(value: LogLevel) = stage {
        logger.logLevel = value
        logDebug("Staged logLevel: $value")
    }

    fun setLogMaxDays(value: Int) = stage {
        logger.logMaxDays = value
        logDebug("Staged logMaxDays: $value")
    }

    // --- Private Helper Methods ---

    private fun stage(action: ConfigEditor.() -> Unit) {
        pendingActions.add(action)
    }

    private fun refreshSnapshot() {
        _snapshot.value = buildSnapshot()
    }

    private fun buildSnapshot(): Snapshot {
        val config = bgGeo.config

        return Snapshot(
            geolocation = GeolocationConfig(
                desiredAccuracy = config.geolocation.desiredAccuracy,
                distanceFilter = config.geolocation.distanceFilter,
                locationUpdateInterval = config.geolocation.locationUpdateInterval,
                fastestLocationUpdateInterval = config.geolocation.fastestLocationUpdateInterval,
                stationaryRadius = config.geolocation.stationaryRadius,
                stopTimeout = config.geolocation.stopTimeout,
                geofenceProximityRadius = config.geolocation.geofenceProximityRadius,
                locationAuthorizationRequest = config.geolocation.locationAuthorizationRequest,
                significantChangesOnly = config.geolocation.useSignificantChangesOnly,
                geofenceModeHighAccuracy = config.geolocation.geofenceModeHighAccuracy,
                disableElasticity = config.geolocation.disableElasticity
            ),
            motion = MotionConfig(
                stopDetectionDelayMs = config.activity.motionTriggerDelay,
                disableMotionActivityUpdates = config.activity.disableMotionActivityUpdates,
                disableStopDetection = config.activity.disableStopDetection
            ),
            http = HttpConfig(
                url = config.http.url,
                autoSync = config.http.autoSync,
                autoSyncThreshold = config.http.autoSyncThreshold,
                batchSync = config.http.batchSync,
                maxBatchSize = config.http.maxBatchSize
            ),
            persistence = PersistenceConfig(
                maxRecordsToPersist = config.persistence.maxRecordsToPersist,
                maxDaysToPersist = config.persistence.maxDaysToPersist,
                persistMode = config.persistence.persistMode
            ),
            application = ApplicationConfig(
                stopOnTerminate = config.app.stopOnTerminate,
                startOnBoot = config.app.startOnBoot,
                heartbeatInterval = config.app.heartbeatInterval
            ),
            logger = DebugConfig(
                debug = config.logger.debug,
                logLevel = config.logger.logLevel,
                logMaxDays = config.logger.logMaxDays
            )
        )
    }

    private fun logDebug(message: String) {
        Log.d(TAG, message)
    }
}

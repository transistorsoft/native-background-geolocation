package com.transistorsoft.tslocationmanager.demo.helpers

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.location.provider.ProviderProperties
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.Tasks
import java.util.concurrent.TimeUnit

/**
 * Injects mock locations for instrumented tests.
 *
 * Supports three modes matching what real mock location apps (e.g. Mockito) offer:
 * - [MockMode.LOCATION_MANAGER] — injects via LocationManager test providers (gps + network).
 *   Feeds into FusedLocationProviderClient from below. Most reliable for triggering SDK location events.
 * - [MockMode.FUSED] — injects via FusedLocationProviderClient.setMockMode().
 *   Only affects FLP consumers with active location requests.
 * - [MockMode.BOTH] — injects via both paths. Most thorough.
 *
 * Usage:
 * ```
 * val mock = MockLocationHelper(context, mode = MockMode.LOCATION_MANAGER)
 * mock.enable()
 * mock.pushLocation(37.422, -122.084, accuracy = 5f)
 * mock.pushLocation(37.422, -122.084, accuracy = 2000f)  // simulate COARSE
 * mock.disable()   // call in @After
 * ```
 */
class MockLocationHelper(
    private val context: Context,
    private val mode: MockMode = MockMode.LOCATION_MANAGER
) {

    enum class MockMode {
        /** Inject via LocationManager test providers (gps + network). Feeds into FLP from below. */
        LOCATION_MANAGER,
        /** Inject via FusedLocationProviderClient.setMockMode(). Requires active FLP request. */
        FUSED,
        /** Inject via both LocationManager and FLP. Most thorough. */
        BOTH,
        /** Inject via `adb emu geo fix` shell command. Emulator only — most reliable, no API quirks. */
        EMULATOR
    }

    companion object {
        private const val TAG = "MockLocationHelper"
        private const val TASK_TIMEOUT_S = 5L
        private val TEST_PROVIDERS = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
    }

    private val locationManager: LocationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val fusedClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private var enabled = false
    private val activeTestProviders = mutableListOf<String>()

    /**
     * Enable mock mode. Must be called before [pushLocation].
     *
     * Automatically grants the mock location appop via UiAutomation (which has shell
     * privileges during instrumented tests).
     */
    fun enable() {
        try {
            // Grant mock location permission via shell — UiAutomation runs as shell uid.
            val packageName = InstrumentationRegistry.getInstrumentation().targetContext.packageName
            val uiAutomation = InstrumentationRegistry.getInstrumentation().uiAutomation
            uiAutomation.executeShellCommand(
                "appops set $packageName android:mock_location allow"
            ).close()
            Thread.sleep(200)

            when (mode) {
                MockMode.LOCATION_MANAGER -> enableLocationManagerProviders()
                MockMode.FUSED -> enableFusedMockMode()
                MockMode.BOTH -> { enableLocationManagerProviders(); enableFusedMockMode() }
                MockMode.EMULATOR -> {
                    // Set up a test provider via shell — UiAutomation has shell uid.
                    val uiAutomation = InstrumentationRegistry.getInstrumentation().uiAutomation
                    uiAutomation.executeShellCommand(
                        "cmd location providers add-test-provider gps requiresNetwork=false requiresSatellite=false requiresCell=false hasMonetaryCost=false supportsAltitude=true supportsSpeed=true supportsBearing=true powerRequirement=1 accuracy=1"
                    ).close()
                    uiAutomation.executeShellCommand(
                        "cmd location providers set-test-provider-enabled gps true"
                    ).close()
                    Thread.sleep(200)
                }
            }

            enabled = true
            Log.i(TAG, "Mock mode enabled (mode=$mode) for $packageName")
        } catch (e: Exception) {
            throw AssertionError("Failed to enable mock mode: ${e.message}", e)
        }
    }

    /**
     * Disable mock mode. Call in @After to restore normal location delivery.
     */
    fun disable() {
        if (!enabled) return
        try {
            when (mode) {
                MockMode.FUSED -> disableFusedMockMode()
                MockMode.LOCATION_MANAGER -> disableLocationManagerProviders()
                MockMode.BOTH -> { disableFusedMockMode(); disableLocationManagerProviders() }
                MockMode.EMULATOR -> {
                    try {
                        val uiAutomation = InstrumentationRegistry.getInstrumentation().uiAutomation
                        uiAutomation.executeShellCommand(
                            "cmd location providers set-test-provider-enabled gps false"
                        ).close()
                        uiAutomation.executeShellCommand(
                            "cmd location providers remove-test-provider gps"
                        ).close()
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to clean up emulator test provider: ${e.message}")
                    }
                }
            }
            enabled = false
            Log.i(TAG, "Mock mode disabled")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to disable mock mode: ${e.message}")
        }
    }

    /**
     * Push a single mock location.
     *
     * @param latitude  Latitude in degrees
     * @param longitude Longitude in degrees
     * @param accuracy  Horizontal accuracy in meters (e.g. 5f for FINE, 2000f for COARSE)
     * @param speed     Speed in m/s (default 0 = stationary)
     * @param bearing   Bearing in degrees (default 0)
     * @param altitude  Altitude in meters (default 0)
     * @param ageMs     How old the location should appear (default 0 = now)
     */
    fun pushLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Float = 5f,
        speed: Float = 0f,
        bearing: Float = 0f,
        altitude: Double = 0.0,
        ageMs: Long = 0L
    ): Location {
        check(enabled) { "Call enable() before pushLocation()" }

        when (mode) {
            MockMode.LOCATION_MANAGER, MockMode.BOTH -> {
                for (provider in activeTestProviders) {
                    val loc = buildLocation(latitude, longitude, accuracy, speed, bearing, altitude, ageMs, provider)
                    locationManager.setTestProviderLocation(provider, loc)
                }
                if (mode == MockMode.BOTH) {
                    val loc = buildLocation(latitude, longitude, accuracy, speed, bearing, altitude, ageMs, "fused")
                    Tasks.await(fusedClient.setMockLocation(loc), TASK_TIMEOUT_S, TimeUnit.SECONDS)
                }
            }
            MockMode.FUSED -> {
                val loc = buildLocation(latitude, longitude, accuracy, speed, bearing, altitude, ageMs, "fused")
                Tasks.await(fusedClient.setMockLocation(loc), TASK_TIMEOUT_S, TimeUnit.SECONDS)
            }
            MockMode.EMULATOR -> {
                // Use shell `cmd location` to set a test location on the GPS provider.
                // Runs via UiAutomation which has shell uid — works on emulators.
                val uiAutomation = InstrumentationRegistry.getInstrumentation().uiAutomation
                uiAutomation.executeShellCommand(
                    "cmd location providers set-test-location gps $latitude $longitude $accuracy $altitude $speed $bearing"
                ).close()
            }
        }

        Log.i(TAG, "Pushed mock location: ($latitude, $longitude) accuracy=${accuracy}m speed=${speed}m/s mode=$mode")
        return buildLocation(latitude, longitude, accuracy, speed, bearing, altitude, ageMs)
    }

    /**
     * Push a sequence of locations with a delay between each.
     * Useful for simulating movement or location sampling.
     */
    fun pushLocations(
        locations: List<LocationSpec>,
        intervalMs: Long = 1000L
    ) {
        for ((i, spec) in locations.withIndex()) {
            pushLocation(
                latitude = spec.latitude,
                longitude = spec.longitude,
                accuracy = spec.accuracy,
                speed = spec.speed,
                bearing = spec.heading,
                altitude = spec.altitude
            )
            if (i < locations.size - 1) {
                Thread.sleep(intervalMs)
            }
        }
    }

    // ── LocationManager test providers ──────────────────────────────────────

    private fun enableLocationManagerProviders() {
        for (provider in TEST_PROVIDERS) {
            try {
                // Remove any stale test provider first.
                try { locationManager.removeTestProvider(provider) } catch (_: Exception) {}

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    locationManager.addTestProvider(
                        provider,
                        false,  // requiresNetwork
                        false,  // requiresSatellite
                        false,  // requiresCell
                        false,  // hasMonetaryCost
                        true,   // supportsAltitude
                        true,   // supportsSpeed
                        true,   // supportsBearing
                        ProviderProperties.POWER_USAGE_LOW,
                        ProviderProperties.ACCURACY_FINE
                    )
                } else {
                    @Suppress("DEPRECATION")
                    locationManager.addTestProvider(
                        provider,
                        false, false, false, false, true, true, true,
                        android.location.Criteria.POWER_LOW,
                        android.location.Criteria.ACCURACY_FINE
                    )
                }
                locationManager.setTestProviderEnabled(provider, true)
                activeTestProviders.add(provider)
                Log.i(TAG, "Registered test provider: $provider")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to register test provider $provider: ${e.message}")
            }
        }
    }

    private fun disableLocationManagerProviders() {
        for (provider in activeTestProviders) {
            try {
                locationManager.setTestProviderEnabled(provider, false)
                locationManager.removeTestProvider(provider)
                Log.i(TAG, "Removed test provider: $provider")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove test provider $provider: ${e.message}")
            }
        }
        activeTestProviders.clear()
    }

    // ── FusedLocationProviderClient mock mode ──────────────────────────────

    private fun enableFusedMockMode() {
        Tasks.await(fusedClient.setMockMode(true), TASK_TIMEOUT_S, TimeUnit.SECONDS)
    }

    private fun disableFusedMockMode() {
        try {
            Tasks.await(fusedClient.setMockMode(false), TASK_TIMEOUT_S, TimeUnit.SECONDS)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to disable FLP mock mode: ${e.message}")
        }
    }

    // ── Location builder ───────────────────────────────────────────────────

    /**
     * Build an android.location.Location with the given parameters.
     */
    fun buildLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Float = 5f,
        speed: Float = 0f,
        bearing: Float = 0f,
        altitude: Double = 0.0,
        ageMs: Long = 0L,
        provider: String = LocationManager.GPS_PROVIDER
    ): Location {
        return Location(provider).apply {
            this.latitude = latitude
            this.longitude = longitude
            this.accuracy = accuracy
            this.speed = speed
            this.bearing = bearing
            this.altitude = altitude
            this.time = System.currentTimeMillis() - ageMs
            this.elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos() - (ageMs * 1_000_000L)
        }
    }

    /**
     * Specification for a mock location, used with [pushLocations].
     */
    data class LocationSpec(
        val latitude: Double,
        val longitude: Double,
        val accuracy: Float = 5f,
        val speed: Float = 0f,
        val heading: Float = 0f,
        val altitude: Double = 0.0
    )
}

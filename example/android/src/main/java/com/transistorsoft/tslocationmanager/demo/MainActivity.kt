package com.transistorsoft.tslocationmanager.demo

import android.os.Bundle
import android.util.Log
import android.view.View
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.tslocationmanager.demo.databinding.ActivityMainBinding
import com.transistorsoft.tslocationmanager.demo.location.LocationManager
import com.transistorsoft.tslocationmanager.demo.map.MapController
import com.transistorsoft.tslocationmanager.demo.ui.FabMenuManager
import com.transistorsoft.tslocationmanager.demo.ui.ToolbarManager
import com.transistorsoft.tslocationmanager.demo.ui.NavigationManager
import com.transistorsoft.tslocationmanager.demo.ui.settings.SettingsBottomSheet

/**
 * Main activity focused purely on orchestrating components and handling lifecycle.
 * Business logic is delegated to specialized managers.
 */
class MainActivity : AppCompatActivity(), OnMapReadyCallback {

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        Log.d(TAG, "[ActivityWindow] onWindowFocusChanged hasFocus=$hasFocus")
    }

    // Activity-scoped lifecycle observer for logging lifecycle events
    private val activityLifecycleObserver = object : DefaultLifecycleObserver {

        override fun onCreate(owner: LifecycleOwner) {
            Log.d(TAG, "[ActivityLifecycle] onCreate")
        }

        override fun onStart(owner: LifecycleOwner) {
            Log.d(TAG, "[ActivityLifecycle] onStart")
        }

        override fun onResume(owner: LifecycleOwner) {
            Log.d(TAG, "[ActivityLifecycle] onResume")
        }

        override fun onPause(owner: LifecycleOwner) {
            Log.d(TAG, "[ActivityLifecycle] onPause")
        }

        override fun onStop(owner: LifecycleOwner) {
            Log.d(TAG, "[ActivityLifecycle] onStop")
        }

        override fun onDestroy(owner: LifecycleOwner) {
            Log.d(TAG, "[ActivityLifecycle] onDestroy")
        }
    }

    private lateinit var binding: ActivityMainBinding
    private val viewModel: MainActivityViewModel by viewModels()

    // Specialized managers for different concerns
    private lateinit var locationManager: LocationManager
    private lateinit var mapController: MapController
    private lateinit var toolbarManager: ToolbarManager
    private lateinit var fabMenuManager: FabMenuManager
    private lateinit var navigationManager: NavigationManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Register the Activity lifecycle observer
        lifecycle.addObserver(activityLifecycleObserver)

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupManagers()

        logSdkState("onCreate")

        Log.d(TAG, "toolbar=${findViewById<View>(R.id.top_toolbar)?.state()}")
        Log.d(TAG, "btn_nav=${findViewById<View>(R.id.btn_navigation)?.state()}")
        Log.d(TAG, "btn_pace=${findViewById<View>(R.id.btn_change_pace)?.state()}")

        setupMap()
        setupObservers()

        // Initialize location tracking if first time
        if (!viewModel.isInitialized) {
            viewModel.isInitialized = true
            locationManager.initialize()
        }
    }

    fun View.state() = "vis=${visibility} enabled=$isEnabled clickable=$isClickable alpha=$alpha"

    private fun setupManagers() {
        val bgGeo = BGGeo.instance

        bgGeo.setActivity(this)

        // Location management
        locationManager = LocationManager(
            activity = this,
            bgGeo = bgGeo,
            lifecycleScope = lifecycleScope
        )

        // Map controller (reuse from ViewModel to survive rotation)
        mapController = viewModel.mapController ?: MapController(this).also {
            viewModel.mapController = it
        }

        // UI managers - using findViewById to match your existing layout IDs
        toolbarManager = ToolbarManager(
            toolbar = findViewById(R.id.top_toolbar),
            onTrackingToggle = { enabled ->
                Log.d(TAG, "toggle enabled: $enabled")

                // Drive SDK
                if (enabled) {
                    locationManager.startTracking()
                } else {
                    locationManager.stopTracking()
                }

                // After a short delay, read the authoritative config snapshot and log what the SDK thinks.
                binding.root.postDelayed({
                    logSdkState("afterToggle($enabled)")
                }, 300)
            }
        )

        fabMenuManager = FabMenuManager(
            fab = findViewById(R.id.fab),
            onSettingsClick = ::showSettings,
            onEmailLogClick = locationManager::emailLog,
            onRequestPermissionClick = locationManager::requestPermission,
            onWatchPositionClick = locationManager::watchPosition,
            onSetOdometerClick = locationManager::resetOdometer,
            onSyncClick = locationManager::sync,
            onDestroyLocationsClick = locationManager::destroyLocations
        )

        navigationManager = NavigationManager(
            getCurrentPositionButton = findViewById(R.id.btn_navigation),
            changePaceButton = findViewById(R.id.btn_change_pace),
            onGetCurrentPosition = locationManager::getCurrentPosition,
            onChangePace = locationManager::changePace,
            odometerTextView = findViewById(R.id.txt_odometer)
        )

        // Connect map controller to location manager
        mapController.bindTo(bgGeo)
        var lastMeters = 0.0
        var lastError: Double? = null
        locationManager.odometerMeters.observe(this) { meters ->
            lastMeters = meters
            navigationManager.updateOdometer(lastMeters, lastError)
        }
        locationManager.odometerErrorMeters.observe(this) { error ->
            lastError = error
            navigationManager.updateOdometer(lastMeters, lastError)
        }
    }

    private fun setupMap() {
        val existingFragment = supportFragmentManager
            .findFragmentById(R.id.map_container) as? SupportMapFragment

        val mapFragment = existingFragment ?: SupportMapFragment.newInstance().also {
            supportFragmentManager.beginTransaction()
                .replace(R.id.map_container, it)
                .commit()
        }

        mapFragment.getMapAsync(this)
    }

    private fun setupObservers() {
        // Location state changes
        locationManager.trackingState.observe(this) { state ->
            toolbarManager.updateTrackingState(state.isTracking, state.isEnabled)
            navigationManager.updateTrackingState(state.isTracking, state.isMoving)

            if (state.isTracking) {
                mapController.enableMyLocation(true)
            } else {
                mapController.enableMyLocation(false)
                mapController.clearOverlays()
            }
        }

        // Listen for settings sheet closing
        supportFragmentManager.setFragmentResultListener("settings_closed", this) { _, _ ->
            fabMenuManager.closeFabMenu()
        }
    }

    override fun onMapReady(map: GoogleMap) {
        mapController.setMap(map)
        Log.d(TAG, "Map ready and connected to controller")
    }

    private fun showSettings() {
        SettingsBottomSheet().show(supportFragmentManager, "SettingsBottomSheet")
    }

    override fun onDestroy() {
        // Remove the Activity lifecycle observer before calling super
        lifecycle.removeObserver(activityLifecycleObserver)
        mapController.unbindFrom(BGGeo.instance)
        locationManager.cleanup()

        super.onDestroy()
    }

    private fun logSdkState(where: String) {
        try {
            val config = BGGeo.instance.config
            val enabled = config.enabled
            Log.d(
                TAG,
                "SDK state @$where → enabled=$enabled"
            )
        } catch (t: Throwable) {
            Log.e(TAG, "logSdkState@$where failed: ${t.message}")
        }
    }
}

package com.transistorsoft.bggeo.kotlin.demo.map

import android.content.Context
import android.util.Log
import android.util.TypedValue
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.EventSubscription
import com.transistorsoft.locationmanager.kotlin.events.LocationEvent
import com.transistorsoft.bggeo.kotlin.demo.ui.geofence.GeofenceSheet
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

/**
 * Core map controller focused on basic map management and coordination.
 * Delegates specialized functionality to focused manager classes.
 */
class MapController(private val context: Context) {

    companion object {
        private const val TAG = "MapController"
        private const val DEFAULT_ZOOM = 16f
    }

    // Specialized managers - initialized when map is available
    private var locationVisualizationManager: LocationVisualizationManager? = null
    private var geofenceOverlayManager: GeofenceOverlayManager? = null
    private var polygonCaptureManager: PolygonCaptureManager? = null

    // Core map state
    private var googleMap: GoogleMap? = null
    private var lastFocus: LatLng? = null
    private var lastZoom: Float = DEFAULT_ZOOM
    private var isFollowing: Boolean = true

    // Event subscriptions
    private val subscriptions = mutableSetOf<EventSubscription>()

    // Coroutine scope for geofence operations
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Store BGGeo reference for deferred binding
    private var bgGeoRef: BGGeo? = null

    /**
     * Set the Google Map instance and initialize all components
     */
    fun setMap(map: GoogleMap) {
        this.googleMap = map
        setupMapSettings(map)
        initializeManagers(map)
        restoreCamera()
    }

    private fun setupMapSettings(map: GoogleMap) {
        map.uiSettings.apply {
            isCompassEnabled = true
            isMapToolbarEnabled = false
        }

        // Track camera changes
        map.setOnCameraIdleListener {
            map.cameraPosition?.let { position ->
                lastFocus = position.target
                lastZoom = position.zoom
            }
        }

        // Disable following when user manually moves map
        map.setOnCameraMoveStartedListener { reason ->
            if (reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE) {
                isFollowing = false
                Log.d(TAG, "Follow disabled by user gesture")
            }
        }

        // Handle long press for geofence creation
        map.setOnMapLongClickListener { latLng ->
            onMapLongPress(latLng)
        }
    }

    private fun initializeManagers(map: GoogleMap) {
        locationVisualizationManager = LocationVisualizationManager(context, map)
        geofenceOverlayManager = GeofenceOverlayManager(context, map)
        polygonCaptureManager = PolygonCaptureManager(context, map) { vertices ->
            // Polygon vertices captured — show the Add Geofence sheet
            showGeofenceSheet(vertices = vertices)
        }

        // Re-render all existing overlays on new map instance
        locationVisualizationManager?.reRenderAll()
        geofenceOverlayManager?.reRenderAll()

        // If we already have a BGGeo reference, bind the geofence manager
        bgGeoRef?.let { bgGeo ->
            geofenceOverlayManager?.bindTo(bgGeo)
        }
    }

    private fun restoreCamera() {
        val map = googleMap ?: return
        lastFocus?.let { target ->
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(target, lastZoom))
        } ?: showInitialLocation()
    }

    // -------------------------------------------------------------------------
    // Geofence creation flow
    // -------------------------------------------------------------------------

    private fun onMapLongPress(latLng: LatLng) {
        if (polygonCaptureManager?.isCapturing == true) return
        showGeofenceTypeChoice(latLng)
    }

    /**
     * Step 1: Ask user what kind of geofence to create.
     */
    private fun showGeofenceTypeChoice(latLng: LatLng) {
        val map = googleMap ?: return
        val dialog = BottomSheetDialog(context)
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(12), dp(16), dp(12))
        }

        container.addView(TextView(context).apply {
            text = "Add Geofence"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(0, 0, 0, dp(8))
        })

        container.addView(createOption("Circular") {
            dialog.dismiss()
            showGeofenceSheet(center = latLng)
        })
        container.addView(createOption("Polygon") {
            dialog.dismiss()
            polygonCaptureManager?.begin()
        })

        dialog.setContentView(container)
        dialog.show()
    }

    /**
     * Step 2: Show the common "Add Geofence" sheet.
     */
    private fun showGeofenceSheet(
        center: LatLng? = null,
        vertices: List<LatLng>? = null
    ) {
        val map = googleMap ?: return
        GeofenceSheet(
            context = context,
            googleMap = map,
            scope = scope,
            center = center,
            vertices = vertices
        ).show()
    }

    private fun createOption(text: String, onClick: () -> Unit): TextView {
        return TextView(context).apply {
            setText(text)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(0, dp(14), 0, dp(14))
            setOnClickListener { onClick() }
        }
    }

    private fun dp(value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
    }

    // -------------------------------------------------------------------------
    // BGGeo event binding
    // -------------------------------------------------------------------------

    fun bindTo(bgGeo: BGGeo) {
        if (subscriptions.isNotEmpty()) return

        this.bgGeoRef = bgGeo

        bgGeo.onActivityChange { event ->
            Log.d(TAG, "Activity changed Rx: $event")
        }.storeIn(subscriptions)

        bgGeo.onLocation { event ->
            Log.d(TAG, "Location received: ${event.location}")
            handleLocationUpdate(event)
        }.storeIn(subscriptions)

        bgGeo.onMotionChange { event ->
            Log.d(TAG, "Motion change: isMoving=${event.isMoving}")
            handleMotionChange(event)
        }.storeIn(subscriptions)

        bgGeo.onEnabledChange { event ->
            Log.d(TAG, "Tracking enabled changed: ${event.enabled}")
            if (!event.enabled) {
                clearOverlays()
            }
        }.storeIn(subscriptions)

        bgGeo.onProviderChange { event ->
            Log.d(TAG, "Provider change: $event")
        }.storeIn(subscriptions)

        geofenceOverlayManager?.bindTo(bgGeo)
    }

    fun unbindFrom(bgGeo: BGGeo) {
        subscriptions.forEach { it.close() }
        subscriptions.clear()

        geofenceOverlayManager?.unbindFrom(bgGeo)
        this.bgGeoRef = null
    }

    // -------------------------------------------------------------------------
    // Location handling
    // -------------------------------------------------------------------------

    private fun handleLocationUpdate(event: LocationEvent) {
        val latLng = LatLng(event.location.latitude, event.location.longitude)

        locationVisualizationManager?.addLocationPoint(event.location)

        val extras = event.extras
        if (extras != null && extras.containsKey("getCurrentPosition")) {
            isFollowing = true
        }

        if (isFollowing) {
            val map = googleMap ?: return
            val zoom = map.cameraPosition.zoom
            map.animateCamera(CameraUpdateFactory.newLatLngZoom(latLng, zoom))
        }

        lastFocus = latLng
    }

    private fun handleMotionChange(event: LocationEvent) {
        locationVisualizationManager?.handleMotionChange(event)
        isFollowing = true
        handleLocationUpdate(event)
    }

    fun enableMyLocation(enable: Boolean) {
        val map = googleMap ?: return
        try {
            map.isMyLocationEnabled = enable
            map.uiSettings.isMyLocationButtonEnabled = enable
        } catch (_: SecurityException) {}
    }

    fun clearOverlays() {
        val map = googleMap ?: return
        map.clear()

        locationVisualizationManager?.clearAll()
        geofenceOverlayManager?.clearAll()
        polygonCaptureManager?.clearAll()

        Log.d(TAG, "All map overlays cleared")
    }

    fun showInitialLocation() {
        val map = googleMap ?: return
        val toronto = LatLng(43.6532, -79.3832)
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(toronto, DEFAULT_ZOOM))
    }

    fun getMap(): GoogleMap? = googleMap
}

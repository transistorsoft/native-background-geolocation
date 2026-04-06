package com.transistorsoft.bggeo.kotlin.demo.map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.location.Location
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.*
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.events.LocationEvent
import com.transistorsoft.bggeo.kotlin.demo.R

/**
 * Manages location visualization on the map including trails, markers, and stationary areas.
 * Handles all location-related overlays and animations.
 */
class LocationVisualizationManager(
    private val context: Context,
    private val googleMap: GoogleMap
) {
    // Trail visualization
    private var trail: Polyline? = null
    private val trailPoints = mutableListOf<LatLng>()
    private var firstDot: Circle? = null

    // Stationary visualization
    private var stationaryCircle: Circle? = null
    private var stationaryCenterModel: LatLng? = null
    private var stationaryRadiusModel: Double? = null

    // Stop points and activation segments
    private val stopPoints = mutableListOf<Marker>()
    private val stopPointPositions = mutableListOf<LatLng>()
    private val activationPolylines = mutableListOf<Polyline>()
    private val activationSegmentModels = mutableListOf<Pair<LatLng, LatLng>>()

    // Cached icons
    private val chevronIcon: BitmapDescriptor by lazy {
        // Tweak this dp to scale breadcrumb chevrons up/down
        createScaledResourceIcon(R.drawable.location_arrow_blue, sizeDp = 18f)
    }

    private val stopIcon: BitmapDescriptor by lazy {
        createStopPointIcon()
    }

    /**
     * Add a new location point to the visualization
     */
    fun addLocationPoint(location: Location) {
        val latLng = LatLng(location.latitude, location.longitude)
        val heading = if (location.hasBearing()) location.bearing else 0f

        // Add to trail
        addToTrail(latLng)

        // Add breadcrumb marker
        addBreadcrumbMarker(latLng, heading)
    }

    private fun addToTrail(latLng: LatLng) {
        trailPoints.add(latLng)

        // Ensure trail polyline exists
        if (trail == null) {
            trail = googleMap.addPolyline(
                PolylineOptions()
                    .width(24f)
                    .color(Color.argb(170, 114, 190, 242))
                    .geodesic(true)
                    .zIndex(0f)
            )
        }

        when (trailPoints.size) {
            1 -> {
                // First point - show a dot since polylines need 2+ points
                firstDot?.remove()
                firstDot = googleMap.addCircle(
                    CircleOptions()
                        .center(latLng)
                        .radius(2.0)
                        .strokeWidth(0f)
                        .fillColor(Color.argb(180, 33, 150, 243))
                        .zIndex(0f)
                )
            }
            else -> {
                // 2+ points - update polyline and remove first dot
                trail?.points = trailPoints
                firstDot?.remove()
                firstDot = null
            }
        }
    }

    private fun addBreadcrumbMarker(latLng: LatLng, heading: Float) {
        googleMap.addMarker(
            MarkerOptions()
                .position(latLng)
                .icon(chevronIcon)
                .flat(true)
                .rotation(heading)
                .anchor(0.5f, 0.5f)
                .alpha(0.8f)
                .zIndex(1f)
        )
    }

    /**
     * Handle motion state changes (moving/stationary)
     */
    fun handleMotionChange(event: LocationEvent) {
        val latLng = LatLng(event.location.latitude, event.location.longitude)
        val config = BGGeo.instance.config

        if (!event.isMoving) {
            // Became stationary - show stationary circle
            showStationaryCircle(latLng, config.geolocation.stationaryRadius.toDouble())
        } else {
            // Became moving - convert stationary circle to stop point and show activation segment
            handleMovingTransition(latLng)
        }
    }

    private fun showStationaryCircle(center: LatLng, radiusMeters: Double) {
        // Remove existing stationary circle
        stationaryCircle?.remove()

        // Create new stationary circle
        stationaryCircle = googleMap.addCircle(
            CircleOptions()
                .center(center)
                .radius(radiusMeters)
                .strokeWidth(3f)
                .strokeColor(Color.argb(180, 183, 28, 28))
                .fillColor(Color.argb(80, 244, 67, 54))
                .zIndex(0f)
        )

        // Update model
        stationaryCenterModel = center
        stationaryRadiusModel = radiusMeters
    }

    private fun handleMovingTransition(currentLocation: LatLng) {
        val previousCenter = stationaryCircle?.center ?: currentLocation

        // Remove stationary circle
        stationaryCircle?.remove()
        stationaryCircle = null

        // Add stop point marker
        val stopMarker = googleMap.addMarker(
            MarkerOptions()
                .position(previousCenter)
                .icon(stopIcon)
                .anchor(0.5f, 0.5f)
                .zIndex(1f)
        )
        stopMarker?.let { stopPoints.add(it) }
        stopPointPositions.add(previousCenter)

        // Add activation segment (green line showing trigger distance)
        val activationSegment = googleMap.addPolyline(
            PolylineOptions()
                .add(previousCenter, currentLocation)
                .width(24f)
                .color(Color.argb(200, 76, 175, 80))
                .geodesic(true)
                .zIndex(0.5f)
        )
        activationPolylines.add(activationSegment)
        activationSegmentModels.add(previousCenter to currentLocation)

        // Clear stationary model
        stationaryCenterModel = null
        stationaryRadiusModel = null
    }

    /**
     * Re-render all overlays (called after map rotation)
     */
    fun reRenderAll() {
        // Re-create trail
        trail?.remove()
        trail = null
        if (trailPoints.isNotEmpty()) {
            trail = googleMap.addPolyline(
                PolylineOptions()
                    .addAll(trailPoints)
                    .width(24f)
                    .color(Color.argb(170, 114, 190, 242))
                    .geodesic(true)
                    .zIndex(0f)
            )
        }

        // Re-create stationary circle
        val center = stationaryCenterModel
        val radius = stationaryRadiusModel
        if (center != null && radius != null) {
            stationaryCircle = googleMap.addCircle(
                CircleOptions()
                    .center(center)
                    .radius(radius)
                    .strokeWidth(3f)
                    .strokeColor(Color.argb(180, 183, 28, 28))
                    .fillColor(Color.argb(80, 244, 67, 54))
                    .zIndex(0f)
            )
        }

        // Re-create stop points
        stopPoints.clear()
        stopPointPositions.forEach { position ->
            val marker = googleMap.addMarker(
                MarkerOptions()
                    .position(position)
                    .icon(stopIcon)
                    .anchor(0.5f, 0.5f)
                    .zIndex(1f)
            )
            marker?.let { stopPoints.add(it) }
        }

        // Re-create activation segments
        activationPolylines.clear()
        activationSegmentModels.forEach { (from, to) ->
            val polyline = googleMap.addPolyline(
                PolylineOptions()
                    .add(from, to)
                    .width(24f)
                    .color(Color.argb(200, 76, 175, 80))
                    .geodesic(true)
                    .zIndex(0.5f)
            )
            activationPolylines.add(polyline)
        }
    }

    /**
     * Clear all visualization elements
     */
    fun clearAll() {
        // Clear overlays
        trail?.remove()
        trail = null
        firstDot?.remove()
        firstDot = null
        stationaryCircle?.remove()
        stationaryCircle = null
        stopPoints.forEach { it.remove() }
        stopPoints.clear()
        activationPolylines.forEach { it.remove() }
        activationPolylines.clear()

        // Clear models
        trailPoints.clear()
        stationaryCenterModel = null
        stationaryRadiusModel = null
        stopPointPositions.clear()
        activationSegmentModels.clear()
    }

    private fun createScaledResourceIcon(@androidx.annotation.DrawableRes resId: Int, sizeDp: Float): BitmapDescriptor {
        val density = context.resources.displayMetrics.density
        val targetPx = (sizeDp * density).toInt().coerceAtLeast(1)

        val original = BitmapFactory.decodeResource(context.resources, resId)
        val scaled = Bitmap.createScaledBitmap(original, targetPx, targetPx, true)
        if (scaled != original) {
            original.recycle()
        }
        return BitmapDescriptorFactory.fromBitmap(scaled)
    }

    private fun createStopPointIcon(): BitmapDescriptor {
        val sizeDp = 24f
        val strokeDp = 2f
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(8)
        val strokePx = (strokeDp * density).coerceAtLeast(1f)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val centerX = sizePx / 2f
        val centerY = sizePx / 2f
        val radius = (sizePx / 2f) - strokePx

        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(110, 244, 67, 54)
            style = Paint.Style.FILL
        }
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(200, 183, 28, 28)
            style = Paint.Style.STROKE
            strokeWidth = strokePx
        }

        canvas.drawCircle(centerX, centerY, radius, fillPaint)
        canvas.drawCircle(centerX, centerY, radius, strokePaint)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }
}
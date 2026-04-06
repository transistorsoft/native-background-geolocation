package com.transistorsoft.tslocationmanager.demo.map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.Log
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.*
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.EventSubscription
import com.transistorsoft.locationmanager.kotlin.events.GeofenceEvent
import com.transistorsoft.locationmanager.kotlin.events.GeofencesChangeEvent
import com.transistorsoft.tslocationmanager.demo.util.Geospatial

/**
 * Manages geofence overlays and event visualizations on the map.
 * Handles geofence circles, polygons, and hit markers.
 */
class GeofenceOverlayManager(
    private val context: Context,
    private val googleMap: GoogleMap
) {
    companion object {
        private const val TAG = "GeofenceOverlayManager"
    }

    // Geofence overlays keyed by identifier
    private val geofenceCircles = mutableMapOf<String, Circle>()
    private val geofencePolygons = mutableMapOf<String, Polygon>()

    // Geofence hit visuals (ENTER/EXIT/DWELL markers + connector polylines)
    private val geofenceHitMarkers = mutableListOf<Marker>()
    private val geofenceHitPolylines = mutableListOf<Polyline>()
    private val geofenceEventMarkers = mutableListOf<Marker>()

    // Model state (persists across map instances)
    private data class GeofenceOverlayModel(
        val id: String,
        val center: LatLng? = null,
        val radiusMeters: Double? = null,
        val vertices: List<LatLng>? = null
    )

    private data class HitMarkerModel(val position: LatLng, val color: Int)
    private data class EventMarkerModel(val position: LatLng, val color: Int, val rotation: Float)
    private data class HitSegmentModel(val from: LatLng, val to: LatLng)

    private val geofenceModels = mutableMapOf<String, GeofenceOverlayModel>()
    private val hitMarkerModels = mutableListOf<HitMarkerModel>()
    private val eventMarkerModels = mutableListOf<EventMarkerModel>()
    private val hitSegmentModels = mutableListOf<HitSegmentModel>()

    // Event subscriptions
    private val subscriptions = mutableSetOf<EventSubscription>()

    // Dash pattern for polygon borders
    private val dashPattern: List<PatternItem> = listOf(Dash(10f), Gap(10f))

    /**
     * Bind to BGGeo for geofence events
     */
    fun bindTo(bgGeo: BGGeo) {
        bgGeo.onGeofencesChange { event ->
            handleGeofencesChange(event)
        }.storeIn(subscriptions)

        bgGeo.onGeofence { event ->
            handleGeofenceEvent(event)
        }.storeIn(subscriptions)
    }

    /**
     * Unbind from BGGeo
     */
    fun unbindFrom(bgGeo: BGGeo) {
        subscriptions.forEach { it.close() }
        subscriptions.clear()
    }

    private fun handleGeofencesChange(event: GeofencesChangeEvent) {
        val activated = event.on
        val deactivated = event.off

        Log.d(TAG, "Geofences change - activated: ${activated.size}, deactivated: ${deactivated.size}")

        // Handle complete clear
        if (activated.isEmpty() && deactivated.isEmpty()) {
            clearGeofenceOverlays()
            return
        }

        // Remove deactivated geofences
        deactivated.forEach { id ->
            removeGeofenceOverlay(id)
        }

        // Add activated geofences
        activated.forEach { fence ->
            val id = fence.identifier
            val center = LatLng(fence.latitude, fence.longitude)
            val radius = fence.radius.toDouble()

            val model = if (fence.isPolygon) {
                val vertices = fence.vertices?.map { LatLng(it[0], it[1]) }
                GeofenceOverlayModel(id, center, radius, vertices)
            } else {
                GeofenceOverlayModel(id, center, radius, null)
            }

            geofenceModels[id] = model
            drawGeofenceOverlay(model)
        }
    }

    private fun handleGeofenceEvent(event: GeofenceEvent) {
        val fenceCenter = LatLng(event.latitude, event.longitude)
        val radius = event.radius.toDouble()
        val locationEvent = event.location
        val loc = locationEvent.location
        val eventLocation = LatLng(loc.latitude, loc.longitude)
        val rotation = if (loc.hasBearing()) loc.bearing else 0f

        // Compute hit point on the fence perimeter
        val hitPoint = Geospatial.projectHitOnCircle(fenceCenter, radius, eventLocation)

        // Color by transition type
        val action = event.action
        val color = when (action) {
            "ENTER" -> Color.parseColor("#4CAF50") // green
            "EXIT" -> Color.parseColor("#F44336")  // red
            "DWELL" -> Color.parseColor("#FFC107") // amber
            else -> Color.GRAY
        }

        // Add hit marker
        addHitMarker(hitPoint, color)

        // Add connector line from hit point to actual event location
        addHitConnector(hitPoint, eventLocation)

        // Add chevron marker at the actual event location
        addEventMarker(eventLocation, color, rotation)

        Log.d(TAG, "Geofence ${event.identifier} $action at $eventLocation (hit @ $hitPoint)")
        Log.d(TAG, event.toMap().toString())
    }

    private fun drawGeofenceOverlay(model: GeofenceOverlayModel) {
        // Remove existing overlays for this geofence
        removeGeofenceOverlay(model.id)

        // Draw polygon if vertices exist
        val vertices = model.vertices
        if (!vertices.isNullOrEmpty()) {
            val polygon = googleMap.addPolygon(
                PolygonOptions()
                    .addAll(vertices)
                    .strokeColor(Color.argb(220, 3, 155, 229))
                    .strokeWidth(6f)
                    .strokePattern(dashPattern)
                    .fillColor(Color.argb(60, 3, 155, 229))
                    .zIndex(2f)
            )
            geofencePolygons[model.id] = polygon
        }

        // Draw circle if center and radius exist
        val center = model.center
        val radius = model.radiusMeters
        if (center != null && radius != null) {
            val circle = googleMap.addCircle(
                CircleOptions()
                    .center(center)
                    .radius(radius)
                    .strokeColor(Color.argb(200, 103, 58, 183))
                    .strokeWidth(3f)
                    .fillColor(Color.argb(60, 103, 58, 183))
                    .zIndex(2f)
            )
            geofenceCircles[model.id] = circle
        }
    }

    private fun removeGeofenceOverlay(id: String) {
        geofenceModels.remove(id)
        geofenceCircles.remove(id)?.remove()
        geofencePolygons.remove(id)?.remove()
    }

    private fun clearGeofenceOverlays() {
        geofenceCircles.values.forEach { it.remove() }
        geofencePolygons.values.forEach { it.remove() }
        geofenceCircles.clear()
        geofencePolygons.clear()
        geofenceModels.clear()
    }

    private fun addHitMarker(position: LatLng, color: Int) {
        val marker = googleMap.addMarker(
            MarkerOptions()
                .position(position)
                .icon(createHitIcon(color))
                .anchor(0.5f, 0.5f)
                .zIndex(3f)
        )
        marker?.let {
            geofenceHitMarkers.add(it)
            hitMarkerModels.add(HitMarkerModel(position, color))
        }
    }

    private fun addEventMarker(position: LatLng, color: Int, rotation: Float) {
        val marker = googleMap.addMarker(
            MarkerOptions()
                .position(position)
                .icon(createChevronIcon(color))
                .flat(true)
                .rotation(rotation)
                .anchor(0.5f, 0.5f)
                .zIndex(3f)
        )
        marker?.let {
            geofenceEventMarkers.add(it)
            eventMarkerModels.add(EventMarkerModel(position, color, rotation))
        }
    }

    private fun addHitConnector(from: LatLng, to: LatLng) {
        val polyline = googleMap.addPolyline(
            PolylineOptions()
                .add(from, to)
                .width(3f)
                .color(Color.BLACK)
                .geodesic(true)
                .zIndex(3f)
        )
        geofenceHitPolylines.add(polyline)
        hitSegmentModels.add(HitSegmentModel(from, to))
    }

    private fun createHitIcon(color: Int): BitmapDescriptor {
        val sizeDp = 10f
        val strokeDp = 1f
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(6)
        val strokePx = (strokeDp * density).coerceAtLeast(1f)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val centerX = sizePx / 2f
        val centerY = sizePx / 2f
        val radius = (sizePx / 2f) - strokePx

        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.FILL
        }
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = Color.BLACK
            style = Paint.Style.STROKE
            strokeWidth = strokePx
        }

        canvas.drawCircle(centerX, centerY, radius, fillPaint)
        canvas.drawCircle(centerX, centerY, radius, strokePaint)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    private fun createChevronIcon(color: Int): BitmapDescriptor {
        val sizeDp = 24f
        val strokeDp = 1.25f
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(10)
        val strokePx = (strokeDp * density).coerceAtLeast(1f)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.FILL
        }
        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = Color.BLACK
            style = Paint.Style.STROKE
            strokeWidth = strokePx
            strokeJoin = Paint.Join.ROUND
        }

        val w = sizePx.toFloat()
        val h = sizePx.toFloat()
        val pad = strokePx + (2f * density)

        val cx = w / 2f
        val tipY = pad
        val baseY = h - pad
        val triHeight = (baseY - tipY).coerceAtLeast(1f)
        val baseScale = 1.3f
        val baseWidth = (triHeight * (2.0 / kotlin.math.sqrt(15.0))).toFloat() * baseScale

        val maxHalfBase = (w / 2f) - pad
        val hb = (baseWidth / 2f).coerceAtMost(maxHalfBase)

        val notchShoulderY = tipY + triHeight * 0.90f
        val notchPointY = tipY + triHeight * 0.74f
        val notchInset = hb * 0.30f

        val path = android.graphics.Path().apply {
            moveTo(cx, tipY)
            lineTo(cx + hb, baseY)
            lineTo(cx + hb - notchInset, notchShoulderY)
            lineTo(cx, notchPointY)
            lineTo(cx - hb + notchInset, notchShoulderY)
            lineTo(cx - hb, baseY)
            close()
        }

        canvas.drawPath(path, fill)
        canvas.drawPath(path, stroke)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    /**
     * Re-render all geofence overlays (called after map rotation)
     */
    fun reRenderAll() {
        geofenceCircles.values.forEach { it.remove() }
        geofencePolygons.values.forEach { it.remove() }
        geofenceCircles.clear()
        geofencePolygons.clear()

        geofenceHitMarkers.forEach { it.remove() }
        geofenceHitPolylines.forEach { it.remove() }
        geofenceHitMarkers.clear()
        geofenceHitPolylines.clear()

        geofenceEventMarkers.forEach { it.remove() }
        geofenceEventMarkers.clear()

        geofenceModels.values.forEach { model ->
            drawGeofenceOverlay(model)
        }

        hitMarkerModels.forEach { marker ->
            addHitMarker(marker.position, marker.color)
        }

        eventMarkerModels.forEach { m ->
            addEventMarker(m.position, m.color, m.rotation)
        }

        hitSegmentModels.forEach { segment ->
            addHitConnector(segment.from, segment.to)
        }
    }

    /**
     * Clear all geofence overlays and models
     */
    fun clearAll() {
        clearGeofenceOverlays()

        geofenceHitMarkers.forEach { it.remove() }
        geofenceHitPolylines.forEach { it.remove() }
        geofenceHitMarkers.clear()
        geofenceHitPolylines.clear()

        geofenceEventMarkers.forEach { it.remove() }
        geofenceEventMarkers.clear()

        hitMarkerModels.clear()
        eventMarkerModels.clear()
        hitSegmentModels.clear()
    }
}

package com.transistorsoft.tslocationmanager.demo.map

import android.app.Activity
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.Dash
import com.google.android.gms.maps.model.Gap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.PatternItem
import com.google.android.gms.maps.model.Polygon
import com.google.android.gms.maps.model.PolygonOptions
import com.google.android.gms.maps.model.Polyline
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.imageview.ShapeableImageView
import com.transistorsoft.tslocationmanager.demo.R

/**
 * Manages polygon vertex capture on the map.
 *
 * Responsibility: show a HUD for placing vertices, preview the polygon shape,
 * and deliver the captured vertices via [onVerticesCaptured] when the user taps "Next".
 *
 * Does NOT create geofences — that is [GeofenceSheet]'s job.
 */
class PolygonCaptureManager(
    private val context: Context,
    private val googleMap: GoogleMap,
    private val onVerticesCaptured: (vertices: List<LatLng>) -> Unit
) {
    private var polygonMode = false
    private var polygonHud: View? = null
    private var polygonHudNextBtn: MaterialButton? = null
    private var polygonHudCancelBtn: MaterialButton? = null
    private var polygonHudUndoBtn: View? = null

    // Polygon capture state
    private val polygonVertices = mutableListOf<LatLng>()
    private val polygonVertexMarkers = mutableListOf<Marker>()

    // Preview overlays
    private var previewPolyline: Polyline? = null
    private var previewPolygon: Polygon? = null

    // Dash pattern for polygon preview
    private val dashPattern: List<PatternItem> = listOf(Dash(10f), Gap(10f))

    val isCapturing: Boolean get() = polygonMode

    /**
     * Begin polygon vertex capture mode.
     */
    fun begin() {
        if (polygonMode) return

        polygonMode = true
        showPolygonHud()

        googleMap.setOnMapClickListener { latLng ->
            if (polygonMode) addPolygonVertex(latLng)
        }

        updatePolygonHud()
    }

    private fun addPolygonVertex(point: LatLng) {
        polygonVertices.add(point)
        val index = polygonVertices.size

        val marker = googleMap.addMarker(
            MarkerOptions()
                .position(point)
                .icon(createVertexIcon(index))
                .anchor(0.5f, 0.5f)
                .zIndex(4f)
        )
        marker?.let { polygonVertexMarkers.add(it) }

        updatePolygonPreview()
    }

    private fun updatePolygonPreview() {
        updatePolygonHud()
        val vertices = polygonVertices.toList()

        if (vertices.size >= 3) {
            previewPolygon?.remove()
            previewPolygon = googleMap.addPolygon(
                PolygonOptions()
                    .addAll(vertices)
                    .strokeColor(Color.argb(220, 3, 155, 229))
                    .strokeWidth(6f)
                    .strokePattern(dashPattern)
                    .fillColor(Color.argb(60, 3, 155, 229))
                    .zIndex(2f)
            )
        } else {
            previewPolygon?.remove()
            previewPolygon = null
        }
    }

    private fun createVertexIcon(index: Int): BitmapDescriptor {
        val sizeDp = 28f
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt()

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val centerX = sizePx / 2f
        val centerY = sizePx / 2f
        val radius = sizePx / 2.5f

        val paintCircle = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            style = Paint.Style.FILL
        }
        val paintText = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = sizePx / 2.5f
            textAlign = Paint.Align.CENTER
        }

        canvas.drawCircle(centerX, centerY, radius, paintCircle)
        val textY = centerY - (paintText.descent() + paintText.ascent()) / 2
        canvas.drawText(index.toString(), centerX, textY, paintText)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    private fun showPolygonHud() {
        if (polygonHud != null) return
        val activity = context as? Activity ?: return
        // Add to map_container so it renders below the toolbar, not over the status bar
        val mapContainer = activity.findViewById<ViewGroup>(R.id.map_container) ?: return

        // Single row: [Undo] [Text] <spacer> [Cancel] [Next]
        val bar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { gravity = Gravity.TOP }
            setBackgroundColor(Color.argb(180, 0, 0, 0))
            setPadding(dp(8), dp(8), dp(8), dp(8))
        }

        val undo = ShapeableImageView(context).apply {
            setImageResource(R.drawable.ic_outline_undo_24)
            alpha = 0.3f
            imageTintList = ColorStateList.valueOf(Color.WHITE)
            val outValue = TypedValue()
            context.theme.resolveAttribute(android.R.attr.selectableItemBackgroundBorderless, outValue, true)
            background = ContextCompat.getDrawable(context, outValue.resourceId)
            layoutParams = LinearLayout.LayoutParams(dp(28), dp(28)).apply { marginEnd = dp(4) }
            contentDescription = "Undo last vertex"
            setOnClickListener { undoPolygonVertex() }
        }
        polygonHudUndoBtn = undo

        val message = TextView(context).apply {
            text = "Click map to add vertices"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setTextColor(Color.WHITE)
            setPadding(dp(4), 0, dp(8), 0)
            layoutParams = LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1f  // take remaining space between undo and buttons
            )
        }

        val btnMinWidth = dp(58)
        val btnTextSize = 12f

        val cancel = MaterialButton(
            context,
            null,
            com.google.android.material.R.attr.materialButtonStyle
        ).apply {
            text = "Cancel"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, btnTextSize)
            minWidth = btnMinWidth
            minimumWidth = btnMinWidth
            minHeight = 0
            minimumHeight = 0
            insetTop = 0
            insetBottom = 0
            setPadding(dp(8), dp(4), dp(8), dp(4))
            setOnClickListener { finish(save = false) }
        }
        polygonHudCancelBtn = cancel

        val next = MaterialButton(
            context,
            null,
            com.google.android.material.R.attr.materialButtonStyle
        ).apply {
            text = "Next"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, btnTextSize)
            alpha = 0.5f
            minWidth = btnMinWidth
            minimumWidth = btnMinWidth
            minHeight = 0
            minimumHeight = 0
            insetTop = 0
            insetBottom = 0
            setPadding(dp(8), dp(4), dp(8), dp(4))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { marginStart = dp(8) }
            setOnClickListener {
                if (polygonVertices.size >= 3) finish(save = true)
            }
        }
        polygonHudNextBtn = next

        bar.addView(undo)
        bar.addView(message)
        bar.addView(cancel)
        bar.addView(next)

        mapContainer.addView(bar)
        polygonHud = bar
    }

    private fun undoPolygonVertex() {
        if (polygonVertices.isEmpty()) return

        polygonVertices.removeAt(polygonVertices.lastIndex)
        polygonVertexMarkers.removeLastOrNull()?.remove()

        // Re-number remaining markers
        polygonVertexMarkers.forEachIndexed { index, marker ->
            marker.setIcon(createVertexIcon(index + 1))
        }

        updatePolygonPreview()
    }

    private fun updatePolygonHud() {
        val hasVertices = polygonVertices.isNotEmpty()
        polygonHudUndoBtn?.alpha = if (hasVertices) 1.0f else 0.3f
        polygonHudUndoBtn?.isClickable = hasVertices

        val canFinish = polygonVertices.size >= 3
        polygonHudNextBtn?.alpha = if (canFinish) 1.0f else 0.5f
    }

    private fun finish(save: Boolean) {
        hidePolygonHud()
        polygonMode = false

        if (save && polygonVertices.size >= 3) {
            val captured = polygonVertices.toList()
            cleanup()
            onVerticesCaptured(captured)
        } else {
            cleanup()
        }
    }

    private fun hidePolygonHud() {
        polygonHud?.let { view ->
            val parent = view.parent as? ViewGroup
            parent?.removeView(view)
        }
        polygonHud = null
        polygonHudNextBtn = null
        polygonHudCancelBtn = null
        polygonHudUndoBtn = null
    }

    private fun cleanup() {
        googleMap.setOnMapClickListener(null)
        polygonVertices.clear()
        polygonVertexMarkers.forEach { it.remove() }
        polygonVertexMarkers.clear()
        previewPolyline?.remove()
        previewPolyline = null
        previewPolygon?.remove()
        previewPolygon = null
    }

    /**
     * Clear all polygon capture state (e.g. when map overlays are cleared).
     */
    fun clearAll() {
        if (polygonMode) {
            finish(save = false)
        }
        cleanup()
    }

    private fun dp(value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
    }
}

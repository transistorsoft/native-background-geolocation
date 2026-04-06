package com.transistorsoft.bggeo.kotlin.demo.ui.geofence

import android.content.Context
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.CircleOptions
import com.google.android.gms.maps.model.LatLng
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.materialswitch.MaterialSwitch
import com.google.android.material.textfield.TextInputEditText
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.Geofence
import com.transistorsoft.bggeo.kotlin.demo.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * "Add Geofence" bottom sheet — common form for both circular and polygon geofences.
 *
 * For circular geofences, pass [center] (the long-press location).
 * For polygon geofences, pass [vertices] (captured by PolygonCaptureManager).
 */
class GeofenceSheet(
    private val context: Context,
    private val googleMap: GoogleMap,
    private val scope: CoroutineScope,
    private val center: LatLng? = null,
    private val vertices: List<LatLng>? = null,
    private val onDismiss: (() -> Unit)? = null
) {
    private val isPolygon = vertices != null

    fun show() {
        val dialog = BottomSheetDialog(context)
        val view = LayoutInflater.from(context).inflate(R.layout.sheet_geofence, null, false)
        dialog.setContentView(view)
        setupForm(view, dialog)
        dialog.show()
    }

    private fun setupForm(view: View, dialog: BottomSheetDialog) {
        val idInput = view.findViewById<TextInputEditText>(R.id.txtIdentifier)
        val latInput = view.findViewById<TextInputEditText>(R.id.txtLatitude)
        val lngInput = view.findViewById<TextInputEditText>(R.id.txtLongitude)
        val radiusInput = view.findViewById<TextInputEditText>(R.id.txtRadius)
        val dwellInput = view.findViewById<TextInputEditText>(R.id.txtLoiteringDelay)
        val swEntry = view.findViewById<MaterialSwitch>(R.id.switchNotifyEntry)
        val swExit = view.findViewById<MaterialSwitch>(R.id.switchNotifyExit)
        val swDwell = view.findViewById<MaterialSwitch>(R.id.switchNotifyDwell)
        val btnCancel = view.findViewById<MaterialButton>(R.id.btnCancel)
        val btnAdd = view.findViewById<MaterialButton>(R.id.btnAdd)

        val timestamp = System.currentTimeMillis() / 1000

        if (isPolygon) {
            // Hide lat/lng/radius for polygon geofences
            latInput?.parent?.let { (it as? View)?.visibility = View.GONE }
            lngInput?.parent?.let { (it as? View)?.visibility = View.GONE }
            radiusInput?.parent?.let { (it as? View)?.visibility = View.GONE }
            idInput?.setText("PG-$timestamp")
        } else {
            idInput?.setText("LP-$timestamp")
            latInput?.setText(center?.latitude.toString())
            lngInput?.setText(center?.longitude.toString())
            latInput?.isEnabled = false
            lngInput?.isEnabled = false
            radiusInput?.setText("150")
        }

        dwellInput?.setText("0")
        swEntry?.isChecked = true
        swExit?.isChecked = true
        swDwell?.isChecked = false

        btnCancel?.setOnClickListener {
            dialog.dismiss()
            onDismiss?.invoke()
        }

        btnAdd?.setOnClickListener {
            createGeofence(view, dialog, timestamp)
        }
    }

    private fun createGeofence(view: View, dialog: BottomSheetDialog, timestamp: Long) {
        try {
            val idInput = view.findViewById<TextInputEditText>(R.id.txtIdentifier)
            val radiusInput = view.findViewById<TextInputEditText>(R.id.txtRadius)
            val dwellInput = view.findViewById<TextInputEditText>(R.id.txtLoiteringDelay)
            val swEntry = view.findViewById<MaterialSwitch>(R.id.switchNotifyEntry)
            val swExit = view.findViewById<MaterialSwitch>(R.id.switchNotifyExit)
            val swDwell = view.findViewById<MaterialSwitch>(R.id.switchNotifyDwell)

            val prefix = if (isPolygon) "PG" else "LP"
            val identifier = idInput?.text?.toString()?.trim().takeIf { !it.isNullOrEmpty() }
                ?: "$prefix-$timestamp"
            val loitering = dwellInput?.text?.toString()?.trim()?.toIntOrNull() ?: 0
            val notifyEntry = swEntry?.isChecked == true
            val notifyExit = swExit?.isChecked == true
            val notifyDwell = swDwell?.isChecked == true

            val extras = mutableMapOf<String, Any>()
            val builder = Geofence.Builder()
                .setIdentifier(identifier)
                .setNotifyOnEntry(notifyEntry)
                .setNotifyOnExit(notifyExit)
                .setNotifyOnDwell(notifyDwell)
                .setLoiteringDelay(loitering)

            if (isPolygon) {
                val vertexPairs = vertices!!.map { listOf(it.latitude, it.longitude) }
                builder.setVertices(vertexPairs)
                extras["radius"] = 200
                extras["vertices"] = vertexPairs
            } else {
                val radius = radiusInput?.text?.toString()?.trim()?.toDoubleOrNull() ?: 150.0
                builder.setLatitude(center!!.latitude)
                    .setLongitude(center.longitude)
                    .setRadius(radius.toFloat())
                extras["center"] = mapOf("latitude" to center.latitude, "longitude" to center.longitude)
                extras["radius"] = radius
            }

            builder.setExtras(extras)
            val geofence = builder.build()

            scope.launch {
                try {
                    BGGeo.instance.geofences.add(geofence)
                    if (!isPolygon && center != null) {
                        val radius = radiusInput?.text?.toString()?.trim()?.toDoubleOrNull() ?: 150.0
                        googleMap.addCircle(
                            CircleOptions()
                                .center(center)
                                .radius(radius)
                                .strokeColor(Color.argb(200, 103, 58, 183))
                                .strokeWidth(3f)
                                .fillColor(Color.argb(60, 103, 58, 183))
                                .zIndex(2f)
                        )
                    }
                } catch (_: Exception) {}
                dialog.dismiss()
                onDismiss?.invoke()
            }
        } catch (_: Exception) {
            dialog.dismiss()
            onDismiss?.invoke()
        }
    }
}

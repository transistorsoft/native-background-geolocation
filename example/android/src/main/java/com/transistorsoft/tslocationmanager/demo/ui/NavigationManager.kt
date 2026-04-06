package com.transistorsoft.tslocationmanager.demo.ui

import android.graphics.Color
import android.widget.ImageButton
import android.widget.TextView
import androidx.appcompat.content.res.AppCompatResources
import com.google.android.material.button.MaterialButton
import com.transistorsoft.tslocationmanager.demo.R

/**
 * Manages navigation controls (current position and pace change buttons).
 * Handles button state updates and user interactions.
 */
class NavigationManager(
    private val getCurrentPositionButton: ImageButton,
    private val changePaceButton: MaterialButton,
    private val odometerTextView: TextView,

    private val onGetCurrentPosition: () -> Unit,
    private val onChangePace: (Boolean) -> Unit
) {
    private var isMoving = false

    private var lastOdometerMeters: Double = 0.0
    private var lastOdometerErrorMeters: Double? = null

    init {
        setupButtons()
    }

    private fun setupButtons() {
        getCurrentPositionButton.setOnClickListener {
            Haptics.selectionChanged(getCurrentPositionButton)
            onGetCurrentPosition()
        }

        changePaceButton.setOnClickListener {
            Haptics.selectionChanged(changePaceButton)
            val newMovingState = !isMoving
            onChangePace(newMovingState)
            isMoving = newMovingState
            updateChangePaceButton()
        }
    }

    /**
     * Update the tracking state and button appearances
     */
    fun updateTrackingState(isTracking: Boolean, isMoving: Boolean) {
        this.isMoving = isMoving
        updateChangePaceButton()

        // Enable/disable buttons based on tracking state
        getCurrentPositionButton.isEnabled = true
        changePaceButton.isEnabled = isTracking
    }

    private fun updateChangePaceButton() {
        val context = changePaceButton.context
        if (isMoving) {
            // Moving → show Pause (red)
            changePaceButton.icon = AppCompatResources.getDrawable(context, R.drawable.ic_pause)
            changePaceButton.backgroundTintList =
                android.content.res.ColorStateList.valueOf(Color.parseColor("#E53935"))
        } else {
            // Stationary → show Play (green)
            changePaceButton.icon = AppCompatResources.getDrawable(context, R.drawable.ic_play_button)
            changePaceButton.backgroundTintList =
                android.content.res.ColorStateList.valueOf(Color.parseColor("#16BE42"))
        }

        changePaceButton.iconTint =
            android.content.res.ColorStateList.valueOf(Color.WHITE)
    }

    fun updateOdometer(meters: Double, errorMeters: Double? = null) {
        lastOdometerMeters = meters
        if (errorMeters != null) {
            lastOdometerErrorMeters = errorMeters
        }
        renderOdometer()
    }

    private fun renderOdometer() {
        val km = lastOdometerMeters / 1000.0
        val text = if (lastOdometerErrorMeters != null) {
            String.format("%.2fkm (± %.0fm)", km, lastOdometerErrorMeters)
        } else {
            String.format("%.2fkm", km)
        }
        odometerTextView.text = text
    }
}
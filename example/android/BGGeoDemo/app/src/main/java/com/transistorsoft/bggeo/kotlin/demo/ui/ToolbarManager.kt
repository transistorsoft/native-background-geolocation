package com.transistorsoft.bggeo.kotlin.demo.ui

import androidx.appcompat.widget.SwitchCompat
import com.google.android.material.appbar.MaterialToolbar
import com.transistorsoft.bggeo.kotlin.demo.R

/**
 * Manages the app toolbar and tracking switch.
 * Handles toolbar setup and state synchronization.
 */
class ToolbarManager(
    private val toolbar: MaterialToolbar,
    private val onTrackingToggle: (Boolean) -> Unit
) {
    private var trackingSwitch: SwitchCompat? = null
    private var isUpdatingProgrammatically = false

    init {
        setupToolbar()
    }

    private fun setupToolbar() {
        toolbar.apply {
            title = context.getString(R.string.app_name)
            menu.clear()
            inflateMenu(R.menu.menu_main)
            overflowIcon = null
        }

        // Setup the tracking switch
        toolbar.post {
            val switchItem = toolbar.menu.findItem(R.id.action_start_stop)
            trackingSwitch = (switchItem.actionView as SwitchCompat).apply {
                showText = false
                setOnCheckedChangeListener { _, isChecked ->
                    // Only respond to user interactions, not programmatic changes
                    if (!isUpdatingProgrammatically) {
                        onTrackingToggle(isChecked)
                    }
                }
            }
        }
    }

    /**
     * Update the tracking state in the toolbar
     */
    fun updateTrackingState(isTracking: Boolean, isEnabled: Boolean) {
        trackingSwitch?.apply {
            // Prevent listener from firing during programmatic update
            isUpdatingProgrammatically = true

            this.isChecked = isTracking  // Fixed: was incorrectly setting to current value
            this.isEnabled = isEnabled

            // Re-enable listener after update
            isUpdatingProgrammatically = false
        }
    }
}
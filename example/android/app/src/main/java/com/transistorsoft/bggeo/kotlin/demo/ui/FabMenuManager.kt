package com.transistorsoft.bggeo.kotlin.demo.ui

import android.content.Context
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.activity.addCallback
import androidx.core.graphics.toColorInt
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.transistorsoft.bggeo.kotlin.demo.R

/**
 * Manages the FAB speed dial menu with animated mini FABs.
 * Handles all FAB-related UI logic and animations.
 */
class FabMenuManager(
    private val fab: FloatingActionButton,
    private val onSettingsClick: () -> Unit,
    private val onEmailLogClick: () -> Unit,
    private val onRequestPermissionClick: () -> Unit,
    private val onWatchPositionClick: () -> Unit,
    private val onSetOdometerClick: () -> Unit,
    private val onSyncClick: () -> Unit,
    private val onDestroyLocationsClick: () -> Unit
) {
    private val context: Context = fab.context
    private var fabMenuOpen = false
    private var fabMenuContainer: LinearLayout? = null
    private val miniFabs = mutableListOf<FloatingActionButton>()

    init {
        setupFabMenu()
        setupBackNavigation()
    }

    private fun setupFabMenu() {
        fab.setOnClickListener {
            if (fabMenuOpen) closeFabMenu() else openFabMenu()
        }

        createFabMenuContainer()
        createMiniFabs()
    }

    private fun setupBackNavigation() {
        val activity = context as? ComponentActivity ?: return
        activity.onBackPressedDispatcher.addCallback(activity) {
            if (fabMenuOpen) {
                closeFabMenu()
            } else {
                isEnabled = false
                activity.onBackPressedDispatcher.onBackPressed()
            }
        }
    }

    private fun createFabMenuContainer() {
        val parent = fab.parent as ViewGroup
        val fabLayoutParams = fab.layoutParams

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
        }

        // Create layout params matching the FAB's parent type
        val layoutParams = createMatchingLayoutParams(fabLayoutParams)

        // Position container above FAB after it's laid out
        fab.post {
            positionContainer(layoutParams, fabLayoutParams)
            container.layoutParams = layoutParams
        }

        parent.addView(container)
        fabMenuContainer = container
    }

    private fun createMatchingLayoutParams(fabParams: ViewGroup.LayoutParams): ViewGroup.LayoutParams {
        return when (fabParams) {
            is FrameLayout.LayoutParams -> FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { gravity = Gravity.BOTTOM or Gravity.END }

            is androidx.coordinatorlayout.widget.CoordinatorLayout.LayoutParams ->
                androidx.coordinatorlayout.widget.CoordinatorLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { gravity = Gravity.BOTTOM or Gravity.END }

            is androidx.constraintlayout.widget.ConstraintLayout.LayoutParams ->
                androidx.constraintlayout.widget.ConstraintLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply {
                    bottomToBottom = androidx.constraintlayout.widget.ConstraintLayout.LayoutParams.PARENT_ID
                    endToEnd = androidx.constraintlayout.widget.ConstraintLayout.LayoutParams.PARENT_ID
                }

            else -> ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
    }

    private fun positionContainer(
        layoutParams: ViewGroup.LayoutParams,
        fabParams: ViewGroup.LayoutParams
    ) {
        val marginLayoutParams = layoutParams as? ViewGroup.MarginLayoutParams ?: return
        val fabMarginParams = fabParams as? ViewGroup.MarginLayoutParams

        val rightMargin = fabMarginParams?.rightMargin
            ?: context.resources.getDimensionPixelSize(R.dimen.fab_margin)
        val bottomMargin = fabMarginParams?.bottomMargin
            ?: context.resources.getDimensionPixelSize(R.dimen.fab_margin)

        // Position above FAB with minimal extra spacing (reduced from 200dp to 20dp)
        marginLayoutParams.setMargins(
            0, 0, rightMargin - dp(6),
            bottomMargin + fab.height + dp(70)
        )
    }

    private fun createMiniFabs() {
        val container = fabMenuContainer ?: return

        val fabConfigs = listOf(
            FabConfig(R.drawable.ic_settings_24, "Settings", onSettingsClick),
            FabConfig(R.drawable.ic_outline_outgoing_mail_24, "Email Log", onEmailLogClick),
            FabConfig(R.drawable.ic_outline_lock_open_right_24, "Request Permission", onRequestPermissionClick),
            FabConfig(R.drawable.ic_navigation, "Watch Position", onWatchPositionClick),
            FabConfig(R.drawable.ic_outline_avg_pace_24, "Set Odometer", onSetOdometerClick),
            FabConfig(R.drawable.ic_outline_cloud_upload_24, "Sync", onSyncClick),
            FabConfig(R.drawable.ic_outline_delete_24, "Destroy Locations", onDestroyLocationsClick)
        )

        // Add FABs in reverse order so first item is closest to main FAB
        fabConfigs.reversed().forEach { config ->
            val miniFab = createMiniFab(config)
            container.addView(miniFab)
            miniFabs.add(miniFab)
        }

        miniFabs.reverse() // Correct order for animations
    }

    private data class FabConfig(
        val iconRes: Int,
        val contentDescription: String,
        val onClick: () -> Unit
    )

    private fun createMiniFab(config: FabConfig): FloatingActionButton {
        return FloatingActionButton(context).apply {
            size = FloatingActionButton.SIZE_MINI
            setImageResource(config.iconRes)
            imageTintList = android.content.res.ColorStateList.valueOf("#1F2937".toColorInt())
            backgroundTintList = android.content.res.ColorStateList.valueOf("#FEDD1E".toColorInt())
            contentDescription = config.contentDescription
            alpha = 0f
            translationY = 0f

            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(10)
                rightMargin = dp(10)
            }

            setOnClickListener {
                config.onClick()
                closeFabMenu()
            }
        }
    }

    fun openFabMenu() {
        val container = fabMenuContainer ?: return

        container.visibility = View.VISIBLE
        fabMenuOpen = true

        // Animate main FAB
        fab.animate().rotation(45f).setDuration(150).start()
        fab.setImageResource(R.drawable.ic_close_24)

        // Staggered animation for mini FABs
        miniFabs.forEachIndexed { index, miniFab ->
            miniFab.alpha = 0f
            miniFab.translationY = 50f
            miniFab.animate()
                .alpha(1f)
                .translationY(0f)
                .setStartDelay((index * 20).toLong())
                .setDuration(120)
                .start()
        }
    }

    fun closeFabMenu() {
        val container = fabMenuContainer ?: return

        fabMenuOpen = false

        // Animate main FAB back
        fab.animate().rotation(0f).setDuration(150).start()
        fab.setImageResource(R.drawable.ic_add_24)

        // Staggered hide animation
        val lastIndex = miniFabs.lastIndex
        miniFabs.forEachIndexed { index, miniFab ->
            miniFab.animate()
                .alpha(0f)
                .translationY(50f)
                .setStartDelay(((lastIndex - index) * 15).toLong())
                .setDuration(100)
                .withEndAction {
                    if (index == lastIndex) {
                        container.visibility = View.GONE
                    }
                }
                .start()
        }
    }

    private fun dp(value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
    }
}
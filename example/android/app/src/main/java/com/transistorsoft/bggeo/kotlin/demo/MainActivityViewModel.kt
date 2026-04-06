package com.transistorsoft.bggeo.kotlin.demo

import androidx.lifecycle.ViewModel
import com.transistorsoft.bggeo.kotlin.demo.map.MapController

/**
 * ViewModel for MainActivity that survives configuration changes.
 * Keeps map controller and initialization state across rotations.
 */
class MainActivityViewModel : ViewModel() {
    var isInitialized = false
    var mapController: MapController? = null

    override fun onCleared() {
        super.onCleared()
        // Cleanup will be handled by MainActivity onDestroy
    }
}
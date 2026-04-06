package com.transistorsoft.tslocationmanager.demo

import com.transistorsoft.locationmanager.kotlin.config.DesiredAccuracy

data class UiConfigState(
    val desiredAccuracy: DesiredAccuracy,
    val trackingMode: UiConfigState.TrackingMode,
    val authorization: UiConfigState.Authorization,
    val disableMotionActivityUpdates: Boolean = false
) {
    enum class TrackingMode { LOCATION_AND_GEOFENCES, GEOFENCES_ONLY }
    enum class Authorization { ALWAYS, WHEN_IN_USE, ANY }
}

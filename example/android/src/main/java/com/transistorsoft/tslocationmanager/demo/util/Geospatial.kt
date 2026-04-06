package com.transistorsoft.tslocationmanager.demo.util

import com.google.android.gms.maps.model.LatLng
import kotlin.math.*

object Geospatial {
    // Mean Earth radius (WGS-84) in meters.
    private const val R = 6_371_000.0

    /** Degrees → radians */
    @JvmStatic fun deg2rad(d: Double) = d * Math.PI / 180.0
    /** Radians → degrees */
    @JvmStatic fun rad2deg(r: Double) = r * 180.0 / Math.PI

    /** Normalize bearing (radians) into (-π, π] */
    @JvmStatic fun normRad(bearingRad: Double): Double {
        var x = (bearingRad + Math.PI) % (2.0 * Math.PI)
        if (x < 0) x += 2.0 * Math.PI
        return x - Math.PI
    }

    /** Initial bearing (radians) from A → B on the sphere. */
    @JvmStatic
    fun bearingRad(a: LatLng, b: LatLng): Double {
        val φ1 = deg2rad(a.latitude)
        val φ2 = deg2rad(b.latitude)
        val Δλ = deg2rad(b.longitude - a.longitude)
        val y = sin(Δλ) * cos(φ2)
        val x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        return atan2(y, x)
    }

    /** Initial bearing (degrees) from A → B. */
    @JvmStatic fun bearingDeg(a: LatLng, b: LatLng) = rad2deg(bearingRad(a, b))

    /** Haversine distance between two coordinates (meters). */
    @JvmStatic
    fun distanceMeters(a: LatLng, b: LatLng): Double {
        val φ1 = deg2rad(a.latitude)
        val φ2 = deg2rad(b.latitude)
        val Δφ = φ2 - φ1
        val Δλ = deg2rad(b.longitude - a.longitude)
        val sinΔφ = sin(Δφ / 2.0)
        val sinΔλ = sin(Δλ / 2.0)
        val h = sinΔφ * sinΔφ + cos(φ1) * cos(φ2) * sinΔλ * sinΔλ
        val c = 2.0 * atan2(sqrt(h), sqrt(1.0 - h))
        return R * c
    }

    /**
     * Destination point given start, distance (m), and initial bearing (radians).
     * Great-circle solution on a spherical Earth.
     */
    @JvmStatic
    fun destinationRad(start: LatLng, distanceMeters: Double, bearingRad: Double): LatLng {
        val δ = distanceMeters / R
        val φ1 = deg2rad(start.latitude)
        val λ1 = deg2rad(start.longitude)
        val θ  = bearingRad

        val sinφ1 = sin(φ1)
        val cosφ1 = cos(φ1)
        val sinδ  = sin(δ)
        val cosδ  = cos(δ)

        val sinφ2 = sinφ1 * cosδ + cosφ1 * sinδ * cos(θ)
        val φ2    = asin(sinφ2)
        val y     = sin(θ) * sinδ * cosφ1
        val x     = cosδ - sinφ1 * sinφ2
        val λ2    = λ1 + atan2(y, x)

        return LatLng(rad2deg(φ2), rad2deg(λ2))
    }

    /** Destination using bearing in degrees. */
    @JvmStatic
    fun destinationDeg(start: LatLng, distanceMeters: Double, bearingDeg: Double): LatLng =
        destinationRad(start, distanceMeters, deg2rad(bearingDeg))

    /**
     * Project a point on a circle (center+radius) in the direction of a target point.
     * Used for “geofence hit” marker on the fence.
     */
    @JvmStatic
    fun projectHitOnCircle(center: LatLng, radiusMeters: Double, toward: LatLng): LatLng {
        val θ = bearingRad(center, toward)
        return destinationRad(center, radiusMeters, θ)
    }
}
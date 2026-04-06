//
//  Geospatial.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-08-20.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//


import Foundation
import CoreLocation

/// Great-circle helpers for projecting points and bearings.
enum Geospatial {
    private static let R: Double = 6_371_000 // mean Earth radius (m)

    @inline(__always) static func toRad(_ d: Double) -> Double { d * .pi / 180 }
    @inline(__always) static func toDeg(_ r: Double) -> Double { r * 180 / .pi }

    /// Initial great-circle bearing in degrees (0..360) from start -> end.
    static func initialBearingGC(from start: CLLocationCoordinate2D,
                                 to end: CLLocationCoordinate2D) -> Double {
        let φ1 = toRad(start.latitude)
        let φ2 = toRad(end.latitude)
        let Δλ = toRad(end.longitude - start.longitude)
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        let θ = atan2(y, x)
        return (toDeg(θ) + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Destination point given start, distance (m), and heading (deg) — great-circle.
    static func destination(from start: CLLocationCoordinate2D,
                            distance meters: Double,
                            bearing headingDeg: Double) -> CLLocationCoordinate2D {
        let δ = meters / R
        let θ = toRad(headingDeg)
        let φ1 = toRad(start.latitude)
        let λ1 = toRad(start.longitude)

        let sinφ1 = sin(φ1), cosφ1 = cos(φ1)
        let sinδ = sin(δ),   cosδ = cos(δ)

        let sinφ2 = sinφ1 * cosδ + cosφ1 * sinδ * cos(θ)
        let φ2 = asin(sinφ2)
        let y = sin(θ) * sinδ * cosφ1
        let x = cosδ - sinφ1 * sinφ2
        let λ2 = λ1 + atan2(y, x)

        return CLLocationCoordinate2D(latitude: toDeg(φ2), longitude: toDeg(λ2))
    }

    /// Point on the circle circumference along the ray center -> point.
    static func projectToCircleEdge(center: CLLocationCoordinate2D,
                                    to point: CLLocationCoordinate2D,
                                    radius meters: Double) -> CLLocationCoordinate2D {
        // If coincident, pick east to draw something predictable.
        if center.latitude == point.latitude && center.longitude == point.longitude {
            return destination(from: center, distance: meters, bearing: 90)
        }
        let brg = initialBearingGC(from: center, to: point)
        return destination(from: center, distance: meters, bearing: brg)
    }
}

//  Colors.swift
//  TSLocationManager Demo
//
//  Centralized color definitions + hex initializers for SwiftUI Color and UIKit UIColor.

import SwiftUI
import UIKit

// MARK: - SwiftUI Color palette

extension Color {
    // --- Brand / base blues ---
    /// Breadcrumb pin fill (darker blue so it pops on the route line)
    static let breadcrumbBlue = Color(hex: 0x1F5AB5)
    /// Route polyline blue
    static let routeBlue = Color(hex: 0x3A81F5)

    // --- Geofence overlays (green & blue themes) ---
    static let geofenceFillGreen  = Color.green.opacity(0.22)
    static let geofenceStrokeGreen = Color.green.opacity(0.70)

    static let geofenceFillBlue  = Color.blue.opacity(0.22)
    static let geofenceStrokeBlue = Color.blue.opacity(0.70)

    // --- Stationary radius (red theme) ---
    static let stationaryFillRed   = Color.red.opacity(0.18)
    static let stationaryStrokeRed = Color.red.opacity(0.80)

    // --- Geofence hit visuals ---
    /// “Stoplight” lime green used for breakout segments
    static let brightGreen = Color(hex: 0x00FF00) // pure lime
    /// Edge markers use ENTER/EXIT/DWELL mapping (see geofenceAction(_:))

    /// Black “ray” from trigger -> circle edge
    static let geofenceRay = Color.black.opacity(0.9)

    // --- Accents / utilities ---
    static let markerOutline = Color.black.opacity(0.30)
    static let markerHalo    = Color.white.opacity(0.90)

    // --- Action mapping ---
    static func geofenceAction(_ action: String) -> Color {
        switch action.uppercased() {
        case "ENTER": return .green
        case "EXIT":  return .red
        case "DWELL": return .yellow
        default:      return .gray
        }
    }
}

// MARK: - UIKit UIColor mirror (optional, if you touch UIKit APIs)

extension UIColor {
    static let breadcrumbBlue    = UIColor(hex: 0x1F5AB5)
    static let routeBlue         = UIColor(hex: 0x3A81F5)

    static let stationaryFillRed   = UIColor.red.withAlphaComponent(0.18)
    static let stationaryStrokeRed = UIColor.red.withAlphaComponent(0.80)

    static let brightGreen = UIColor(hex: 0x00FF00)
    static let geofenceRay    = UIColor(white: 0.0, alpha: 0.90)
}

// MARK: - Hex initializers

extension Color {
    /// Create a Color from 0xRRGGBB, optional alpha 0...1
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >>  8) / 255.0
        let b = Double( hex & 0x0000FF       ) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

extension UIColor {
    /// Create a UIColor from 0xRRGGBB, optional alpha 0...1
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >>  8) / 255.0
        let b = CGFloat( hex & 0x0000FF       ) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

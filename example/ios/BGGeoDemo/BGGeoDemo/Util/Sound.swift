//
//  Sound.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-08-21.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//


import AudioToolbox
import UIKit

/// System sound wrapper.
/// Usage: Sound.play(.longPressActivate)
enum Sound: UInt32 {
    // Map from your Flutter demo:
    case longPressActivate  = 1113
    case longPressCancel    = 1075
    case addGeofence        = 1114
    case buttonClick        = 1104
    case messageSent        = 1303
    case error              = 1006
    case open               = 1502
    case close              = 1503
    case flourish           = 1509
    case testModeClick      = 1130

    /// Play this system sound ID.
    static func play(_ sound: Sound) {
        #if !targetEnvironment(macCatalyst)
        AudioServicesPlaySystemSound(sound.rawValue)
        #endif
    }

    /// Play an arbitrary system sound ID (if you ever need a raw ID).
    static func play(id: UInt32) {
        #if !targetEnvironment(macCatalyst)
        AudioServicesPlaySystemSound(id)
        #endif
    }

    /// Optional: light haptic to pair with sound.
    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }
}

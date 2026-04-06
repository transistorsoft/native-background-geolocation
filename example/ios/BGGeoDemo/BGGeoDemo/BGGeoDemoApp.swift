//
//  BGGeoDemoApp.swift
//  BGGeoDemo
//
//  Created by Christopher Scott on 2026-04-06.
//

import SwiftUI
import BackgroundGeolocation

@main
struct BGGeoDemoApp: App {
    init() {
        let fetchManager = TSBackgroundFetch.sharedInstance()
        fetchManager?.didFinishLaunching()
    }
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

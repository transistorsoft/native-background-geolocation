//
//  DemoApp2App.swift
//  DemoApp2
//
//  Created by Christopher Scott on 2025-08-09.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//

import SwiftUI
import TSBackgroundFetch

@main
struct DemoApp2App: App {
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

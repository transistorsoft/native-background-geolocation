//
//  ToastView.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-09-01.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//


import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .foregroundColor(.white)
            .cornerRadius(12)
            .transition(.opacity)
    }
}

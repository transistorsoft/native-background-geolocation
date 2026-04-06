//
//  FabItem.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-08-14.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//


import SwiftUI
import TSLocationManager

struct FabItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
}

struct FloatingActionMenu: View {
    var items: [FabItem]
    var bottomPadding: CGFloat = 24
    var trailingPadding: CGFloat = 24
    var onToggle: ((Bool) -> Void)?   // <— add this

    @State private var isOpen = false {
        didSet { onToggle?(isOpen) }  // notify whenever toggled
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dim/close tap target when open
            if isOpen {
                Color.black.opacity(0.001) // transparent catch layer
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isOpen = false } }
            }

            // Item column
            VStack(alignment: .trailing, spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        // Label pill
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                            .opacity(isOpen ? 1 : 0)
                            .offset(x: isOpen ? 0 : 8)

                        // Round action button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isOpen.toggle()
                            }
                            item.action()
                        } label: {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 46, height: 46)
                                .background(item.color)
                                .clipShape(Circle())
                        }
                        .opacity(isOpen ? 1 : 0)
                        .offset(y: isOpen ? 0 : 8)
                    }
                    // Staggered reveal
                    .animation(.spring(response: 0.35, dampingFraction: 0.85).delay(isOpen ? Double(index) * 0.03 : 0), value: isOpen)
                }

                // Main FAB
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        print("[BGGeo] enabled: \(BGGeo.shared.state.enabled), state: \(BGGeo.shared.config.toDictionary())")
                        isOpen.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isOpen ? 45 : 0)) // ➕ → ✖️
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOpen)
                        .frame(width: 58, height: 58)
                        .background(Color.black)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
                }
            }
            .padding(.trailing, trailingPadding)
            .padding(.bottom, bottomPadding)
        }
        .allowsHitTesting(true)
    }
}

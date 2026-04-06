//
//  BGGeoChromeView.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-08-11.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//



import SwiftUI
import BackgroundGeolocation
import CoreLocation

extension CLAuthorizationStatus {
    var asString: String {
        switch self {
        case .notDetermined:        return "Not Determined"
        case .restricted:           return "Restricted"
        case .denied:               return "Denied"
        case .authorizedWhenInUse:  return "When In Use"
        case .authorizedAlways:     return "Always"
        @unknown default:           return "Unknown"
        }
    }
}

let fabDiameter: CGFloat = 56        // whatever your FAB renders at
let fabPadding: CGFloat = 12
let radius = fabDiameter / 2

struct HomeView: View {
    @StateObject private var model = LocationManagerModel()
    @State private var showSettings = false
    @State private var showDestroyConfirmation = false
    @State private var pendingLocationCount = 0
    @State private var showEmailPrompt = false
    @State private var emailAddress = UserDefaults.standard.string(forKey: "EmailLogAddress") ?? ""
    @State private var showPermissionDialog = false
    @State private var providerState: BGGeo.ProviderChangeEvent? = nil
    @State private var registrationOrg: String = ""
    @State private var registrationUsername: String = ""
        
    private let chrome = Color(red: 0xFE/255, green: 0xDD/255, blue: 0x1E/255) // #FEDD1E
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // TOP BAR (yellow)
                HStack {
                    Text("BG Geo")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.leading, 16)
                    Spacer()
                    
                    // A = toggle with no label -> model.toggleEnabled()
                    Toggle("", isOn: Binding(
                        get: { model.isEnabled },
                        set: { _ in
                            model.toggleEnabled()
                            Sound.play(.buttonClick)
                            Sound.haptic(.heavy)
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(.trailing, 16)
                }
                .frame(height: 56)
                .background(chrome.ignoresSafeArea(edges: .top))
                
                // CONTENT (white)
                MiddleContentView(model: model)
                
                // BOTTOM BAR (yellow)
                HStack {
                    // B = locate → getCurrentPosition()
                    Button(action: {
                        model.getCurrentPosition()
                        Sound.play(.buttonClick)
                        Sound.haptic(.medium)
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(12)
                            .foregroundColor(.black)
                            .background(Color.black.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(model.isEnabled ? (model.isMoving ? "MOVING" : "STATIONARY") : "DISABLED")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .opacity(0.8)

                        if model.isEnabled {
                            Text(String(format: "%.2f km (\u{00B1} %.0f m)", model.odometer / 1000, model.odometerError))
                                .font(.footnote)
                                .foregroundColor(.black)
                                .opacity(0.6)
                        }
                    }
                    
                    Spacer()
                    
                    // C = play/pause → changePace(); green when play, red when pause
                    Button(action: {
                        model.changePace()
                        Sound.play(.buttonClick)
                        Sound.haptic(.heavy)
                    }) {
                        Image(systemName: model.isMoving ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(model.isMoving ? Color.red : Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!model.isEnabled)
                    .opacity(model.isEnabled ? 1 : 0.5)
                }
                .padding(.horizontal, 16)
                .frame(height: 72)
                .background(chrome.ignoresSafeArea(edges: .bottom))
            }
            
            // Overlay FAB
            FloatingActionMenu(items: [
                FabItem(title: "Destroy locations", systemImage: "trash", color: Color.red) {
                    pendingLocationCount = Int(model.getLocationCount())
                    showDestroyConfirmation = true
                    
                },
                FabItem(title: "Sync", systemImage: "icloud.and.arrow.up",
                        color: Color.yellow) {
                            model.sync()
                        },
                FabItem(title: "Reset odometer", systemImage: "speedometer",
                        color: Color.yellow) {
                            model.resetOdometer()
                        },
                FabItem(title: model.watchId == nil ? "Watch Position" : "Stop Watching",
                        systemImage: "location.fill",
                        color: Color.yellow) {
                    model.watchPosition()
                },
                FabItem(title: "requestPermission", systemImage: "lock.open", color: Color.yellow) {
                    self.providerState = model.getProviderState()
                    self.showPermissionDialog = true
                },
                FabItem(title: "Email Log", systemImage: "tray.and.arrow.up", color: Color.yellow) {
                    showEmailPrompt = true
                },
                FabItem(title: "Config", systemImage: "gearshape", color: Color.yellow) {
                    showSettings = true
                }
            ]) {
                isOpen in
                if isOpen {
                    Sound.play(.open)
                    Sound.haptic(.medium)
                } else {
                    Sound.haptic(.medium)
                }
            }
            .offset(x:8, y:-60)
            .sheet(isPresented: $showSettings) {
                SettingsSheet(model: model)
            }
            .alert(isPresented: $showDestroyConfirmation) {
                Alert(
                    title: Text("Destroy Locations"),
                    message: Text("Destroy \(pendingLocationCount) location(s)?"),
                    primaryButton: .destructive(Text("Confirm")) {
                        model.destroyLocations()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Email Log", isPresented: $showEmailPrompt, actions: {
                TextField("your@email.com", text: $emailAddress)
                Button("Submit") {
                    UserDefaults.standard.set(emailAddress, forKey: "EmailLogAddress")
                    model.emailLog(to: emailAddress)  // or model.emailLog(to: emailAddress) if you wrap it
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("Email contents of the log database.")
            })
            .alert("Demo Server Registration", isPresented: Binding(
                get: { model.needsRegistration },
                set: { _ in }           // dismissal only via Register / Cancel buttons
            )) {
                TextField("Organization name", text: $registrationOrg)
                TextField("Username", text: $registrationUsername)
                Button("Register") {
                    Task { @MainActor in
                        await model.completeInitialRegistration(
                            organization: registrationOrg,
                            username: registrationUsername
                        )
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Register this device with tracker.transistorsoft.com to sync locations.")
            }
            .alert("Location Authorization", isPresented: $showPermissionDialog, actions: {
                Button("When in Use") {
                    model.requestPermission(with: .whenInUse)
                }
                Button("Always") {
                    model.requestPermission(with: .always)
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                if let state = providerState {
                    Text("""
                        Status: \(state.status.asString) (\(state.status.rawValue))
                        Accuracy: \((CLAccuracyAuthorization(rawValue: state.accuracyAuthorization) == .fullAccuracy) ? "FULL" : "REDUCED")
                        Enabled: \(state.enabled ? "Yes" : "No")
                        """)
                } else {
                    Text("Unable to fetch provider state.")
                }
            })
        }
        .overlay(
            Group {
                if let message = model.toastMessage {
                    ToastView(message: message)
                        .padding(.bottom, 100)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    model.toastMessage = nil
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: model.toastMessage)
                }
            },
            alignment: .bottom
        )
    }
}

#Preview { HomeView() }

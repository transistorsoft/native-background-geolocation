import SwiftUI
import MapKit
import Combine
import UIKit
import AudioToolbox

// MARK: - MapView

struct MapView: View {
    @ObservedObject var model: LocationManagerModel

    @State private var camera: MapCameraPosition
    @State private var showGeofenceSheet = false
    @State private var pendingCoordinate: CLLocationCoordinate2D?

    @State private var cameraHeading: CLLocationDirection = 0


    // Polygon build mode
    @State private var isPolygonMode = false
    @State private var polygonVertices: [CLLocationCoordinate2D] = []

    // Shared form sheet
    @State private var showForm = false
    @State private var formMode: GeofenceFormMode?

    init(model: LocationManagerModel) {
        self.model = model
        _camera = State(initialValue: .region(model.region))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $camera) {
                // 1) Semi-transparent blue route line
                trackPolyline
                // 2) Breadcrumbs — persistent markers
                breadcrumbAnnotations
                // 3.5) Green breakout overlays
                breakoutOverlays
                // 4) Stop-points overlay
                stopPointsAnnotations
                // 5) Polygon building visuals
                polygonBuildingOverlays
                // 6) Geofences from the model
                geofenceOverlays
                // 7) Geofence hit markers + rays
                geofenceHitOverlays
                // 3) Stationary radius (red) when not moving
                stationaryOverlay
                if #available(iOS 17.0, *) {
                    UserAnnotation()   // system blue dot
                }
            }
            .mapStyle(
                {
                    if #available(iOS 17.0, *) {
                        return .standard(elevation: .flat, emphasis: .muted)
                    } else {
                        return .standard
                    }
                }()
            )
            .cameraChangeHandlers(model: model, cameraHeading: $cameraHeading)


            // MARK: Gesture handling
            // UIKit-powered long-press recognizer fixes Map gesture conflicts on newer iOS
            .overlay(
                LongPressCapture(isActive: !isPolygonMode && !showGeofenceSheet,
                                 minimumPressDuration: 0.5,
                                 allowableMovement: 12) { point in
                    if let coord = proxy.convert(point, from: .global) {
                        Sound.play(.longPressActivate)
                        Sound.haptic(.heavy)
                        pendingCoordinate = coord
                        showGeofenceSheet = true
                    }
                }
            )
            // Tap-to-add vertex in polygon mode (UIKit-backed)
            .overlay {
                if isPolygonMode {
                    TapCapture(isActive: true) { point in
                        if let coord = proxy.convert(point, from: .global) {
                            addVertex(coord)
                        }
                    }
                }
            }

            .onReceive(model.$region) { newRegion in
                camera = .region(newRegion)
            }

            // Top overlay for polygon mode
            .overlay(alignment: .top) {
                if isPolygonMode {
                    HStack(spacing: 12) {
                        // Undo
                        Button {
                            _ = polygonVertices.popLast()
                            Sound.play(.buttonClick)
                            Sound.haptic(.medium)
                        } label: {
                            Image(systemName: "arrow.uturn.left")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        Spacer(minLength: 8)

                        Text("Click map to add polygon points")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())

                        Spacer(minLength: 8)

                        Button("Cancel") {
                            polygonVertices.removeAll()
                            isPolygonMode = false
                            Sound.play(.buttonClick)
                            Sound.haptic(.medium)
                        }
                        .buttonStyle(.bordered)

                        Button("Next") {
                            Sound.play(.buttonClick)
                            Sound.haptic(.medium)
                            guard polygonVertices.count >= 3 else { return }
                            formMode = .polygon(polygonVertices)
                            showForm = true
                            isPolygonMode = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.light)
        // Action sheet from bottom after long-press
        .confirmationDialog("Add Geofence",
                            isPresented: $showGeofenceSheet,
                            titleVisibility: .visible) {
            Button("Circular") {
                if let coord = pendingCoordinate {
                    formMode = .circular(coord)
                    showForm = true
                    pendingCoordinate = nil
                }
            }
            Button("Polygon") {
                isPolygonMode = true
                polygonVertices.removeAll()
                pendingCoordinate = nil  // Clear pending coordinate
            }
            Button("Cancel", role: .cancel) {
                pendingCoordinate = nil  // Clear pending coordinate on cancel
            }
        }

        // Form sheet (shared for both circular & polygon)
        .sheet(isPresented: $showForm) {
            if let mode = formMode {
                GeofenceFormSheet(mode: mode) { result in
                    switch result {
                    case .circular(let center, let radius, let config):
                        model.addCircularGeofence(at: center,
                                                  radius: radius,
                                                  notifyOnEntry: config.notifyOnEntry,
                                                  notifyOnExit: config.notifyOnExit,
                                                  notifyOnDwell: config.notifyOnDwell,
                                                  loiteringDelayMs: config.loiteringDelayMs,
                                                  extras: ["foo": "bar"],
                                                  identifier: config.identifier)
                    case .polygon(let vertices, let config):
                        model.addPolygonGeofence(vertices: vertices,
                                                 notifyOnEntry: config.notifyOnEntry,
                                                 notifyOnExit: config.notifyOnExit,
                                                 notifyOnDwell: config.notifyOnDwell,
                                                 loiteringDelayMs: config.loiteringDelayMs,
                                                 extras: ["foo": "bar"],
                                                 identifier: config.identifier)
                    }
                    Sound.play(.addGeofence)
                    Sound.haptic(.medium)
                }
            }
        }
    }

    // MARK: Helpers

    // Computed properties to break up complex Map content
    @MapContentBuilder
    private var trackPolyline: some MapContent {
        if model.track.count >= 2 {
            MapPolyline(coordinates: model.track)
                .stroke(Color.routeBlue.opacity(0.50), lineWidth: 10)
                .mapOverlayLevel(level: .aboveLabels)
        }
    }
    
    @MapContentBuilder
    private var breadcrumbAnnotations: some MapContent {
        ForEach(model.points) { p in
            Annotation("", coordinate: p.coord, anchor: .center) {
                Image("location-arrow-blue")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees((p.heading ?? 0) - cameraHeading))
                    .allowsHitTesting(false)
                    // add a subtle white halo so it pops on dark/blue backgrounds
                    .shadow(color: .white.opacity(0.9), radius: 2)
                    // and a faint drop shadow for depth
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .zIndex(5)
            }
        }
    }
    
    @MapContentBuilder
    private var stationaryOverlay: some MapContent {
        if let c = model.stationaryCenter {
            MapCircle(center: c, radius: 200)
                .foregroundStyle(Color.stationaryFillRed)
                .stroke(Color.stationaryStrokeRed, lineWidth: 1)
                .mapOverlayLevel(level: .aboveRoads)
        }
    }
    
    @MapContentBuilder
    private var breakoutOverlays: some MapContent {
        ForEach(Array(model.breakoutSegments.enumerated()), id: \.offset) { _, segment in
            if segment.count >= 2 {
                MapPolyline(coordinates: segment)
                    .stroke(Color.brightGreen, lineWidth: 10)
                    .mapOverlayLevel(level: .aboveRoads)
            }
        }
    }

    @MapContentBuilder
    private var stopPointsAnnotations: some MapContent {
        ForEach(Array(model.stopPoints.enumerated()), id: \.offset) { _, coord in
            Annotation("", coordinate: coord, anchor: .center) {
                // Small red circle (same colors as stationary circle), fixed pixel size
                Circle()
                    .fill(Color.red.opacity(0.18))
                    .overlay(Circle().stroke(Color.red.opacity(0.80), lineWidth: 1))
                    .frame(width: 32, height: 32)   // fixed pixels, won’t scale with zoom
                    .zIndex(20)                     // draw above breadcrumbs
            }
        }
    }
    
    @MapContentBuilder
    private var polygonBuildingOverlays: some MapContent {
        if isPolygonMode {
            let closed = closedPolygonVertices
            
            // Soft translucent fill when 3+ vertices
            if closed.count >= 4 {
                MapPolygon(coordinates: closed)
                    .foregroundStyle(Color.routeBlue.opacity(0.30))
            }

            // Dashed guide line (shows even with 2 points)
            if polygonVertices.count >= 2 {
                MapPolyline(coordinates: closed)
                    .stroke(Color.routeBlue.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [1, 1]))
            }

            // Numbered vertex handles
            ForEach(Array(polygonVertices.enumerated()), id: \.offset) { idx, coord in
                Annotation("", coordinate: coord, anchor: .center) {
                    vertexHandle(index: idx)
                }
            }
        }
    }
    
    @MapContentBuilder
    private var geofenceOverlays: some MapContent {
        let fillGreen = Color.geofenceFillGreen
        let strokeGreen = Color.geofenceStrokeGreen
        
        let fillBlue = Color.geofenceFillBlue
        let strokeBlue = Color.geofenceStrokeBlue
                
        ForEach(Array(model.geofenceOverlays.values)) { overlay in
            switch overlay {
            case let .circle(_, center, radius, _):
                geofenceCircle(center: center, radius: radius)

            case let .polygon(_, vertices, mecCenter, mecRadius, _):
                //let _ = NSLog("🔺 About to render polygon with \(vertices.count) vertices")
                geofencePolygon(vertices: vertices,
                                mecCenter: mecCenter,
                                mecRadius: mecRadius,
                                fill: fillBlue,
                                stroke: strokeBlue)
            }
        }
    }
    
    @MapContentBuilder
    private var geofenceHitOverlays: some MapContent {
        ForEach(model.geofenceHits) { hit in
            // Ray from TRIGGER -> circumference edge
            MapPolyline(coordinates: [hit.trigger, hit.edge])
                .stroke(Color.geofenceRay, lineWidth: 2)
                .mapOverlayLevel(level: .aboveRoads)

            // Small colored dot at the edge intercept
            Annotation("", coordinate: hit.edge, anchor: .center) {
                Circle()
                    .fill(Color.geofenceAction(hit.action))
                    .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                    .frame(width: 8, height: 8)
            }

            // Main colored trigger marker (uses your configurable LocationMarker)
            Annotation("", coordinate: hit.trigger, anchor: .center) {
                LocationMarker(course: (hit.course ?? 0) - cameraHeading, color: Color.geofenceAction(hit.action), size: 22)
                    .frame(width: 16, height: 16)
                    .zIndex(100)
            }
        }
        
    }
    
    private var closedPolygonVertices: [CLLocationCoordinate2D] {
        if polygonVertices.count >= 3, let first = polygonVertices.first {
            return polygonVertices + [first]
        }
        return polygonVertices
    }
    
    private func vertexHandle(index: Int) -> some View {
        ZStack {
            Circle().fill(Color.black)
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 20, height: 20)
        .shadow(radius: 1, y: 1)
    }

    private func addVertex(_ coord: CLLocationCoordinate2D) {
        Sound.play(.buttonClick)
        Sound.haptic(.heavy)
        withAnimation(.easeInOut(duration: 0.15)) {
            polygonVertices.append(coord)
        }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }
    
    @MapContentBuilder
    private func geofenceCircle(center: CLLocationCoordinate2D,
                                radius: CLLocationDistance) -> some MapContent {
        MapCircle(center: center, radius: radius)
            .foregroundStyle(Color.geofenceFillGreen)
            .stroke(Color.geofenceStrokeGreen, lineWidth: 1)
            .mapOverlayLevel(level: .aboveLabels)
    }
    
    // Helper function for logging (outside any result builder)
    private func logPolygonData(vertices: [CLLocationCoordinate2D], mecCenter: CLLocationCoordinate2D, mecRadius: CLLocationDistance) {
        NSLog("🔺 Drawing polygon with \(vertices.count) vertices")
        for (i, vertex) in vertices.enumerated() {
            NSLog("🔺   Vertex \(i): lat=\(vertex.latitude), lng=\(vertex.longitude)")
        }
        NSLog("🔺 MEC center: lat=\(mecCenter.latitude), lng=\(mecCenter.longitude), radius: \(mecRadius)")
    }

    @MapContentBuilder
    private func geofencePolygon(vertices: [CLLocationCoordinate2D],
                                 mecCenter: CLLocationCoordinate2D,
                                 mecRadius: CLLocationDistance,
                                 fill: Color,
                                 stroke: Color) -> some MapContent {
        
        if vertices.count >= 3 {
            let closed = vertices + [vertices.first!]

            // Polygon
            MapPolygon(coordinates: closed)
                .foregroundStyle(fill)
                .mapOverlayLevel(level: .aboveLabels)

            MapPolyline(coordinates: closed)
                .stroke(stroke, style: StrokeStyle(lineWidth: 0.5, dash: [1, 1]))
                .mapOverlayLevel(level: .aboveLabels)
        }

        // MEC circle - SEPARATE instances for fill and stroke
        MapCircle(center: mecCenter, radius: mecRadius)
            .foregroundStyle(Color.green.opacity(0.15))  // Fill only
            .stroke(Color.green.opacity(0.70))
            .mapOverlayLevel(level: .aboveRoads)


    }

}

// MARK: - Form plumbing

enum GeofenceFormMode {
    case circular(CLLocationCoordinate2D)
    case polygon([CLLocationCoordinate2D])
}

struct GeofenceFormConfig {
    var identifier: String = ""
    var notifyOnEntry = true
    var notifyOnExit = true
    var notifyOnDwell = false
    var loiteringDelayMs: Int = 0
}

enum GeofenceFormResult {
    case circular(center: CLLocationCoordinate2D, radius: Double, config: GeofenceFormConfig)
    case polygon(vertices: [CLLocationCoordinate2D], config: GeofenceFormConfig)
}

struct GeofenceFormSheet: View {
    let mode: GeofenceFormMode
    let onSubmit: (GeofenceFormResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var config = GeofenceFormConfig()
    @State private var radius: Double = 200

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add Geofence")) {
                    TextField("identifier", text: $config.identifier)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                }
                Section(header: Text("Geofence Transitions")) {
                    Toggle("notifyOnEntry", isOn: $config.notifyOnEntry)
                    Toggle("notifyOnExit", isOn: $config.notifyOnExit)
                    Toggle("notifyOnDwell", isOn: $config.notifyOnDwell)
                    Stepper("loiteringDelay (milliseconds): \(config.loiteringDelayMs)",
                            value: $config.loiteringDelayMs,
                            in: 0...3_600_000,
                            step: 1_000)
                }
                if case .circular = mode {
                    Section(header: Text("Radius")) {
                        Stepper("Radius: \(Int(radius)) m", value: $radius, in: 50...2000, step: 10)
                    }
                }
            }
            .navigationTitle("Add Geofence")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        switch mode {
                        case .circular(let center):
                            onSubmit(.circular(center: center, radius: radius, config: config))
                        case .polygon(let vertices):
                            onSubmit(.polygon(vertices: vertices, config: config))
                        }
                        dismiss()
                    }
                    .disabled(config.identifier.isEmpty)
                }
            }
        }
    }
}

// MARK: - Camera change handling (availability-safe)

private struct CameraChangeModifier: ViewModifier {
    @ObservedObject var model: LocationManagerModel
    @Binding var cameraHeading: CLLocationDirection

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onMapCameraChange(frequency: .continuous) { context in
                if let until = model.suppressUnfollowUntil, Date() < until { return }
                model.followsLocation = false
                cameraHeading = context.camera.heading
            }
        } else {
            content.onMapCameraChange(frequency: .continuous) {
                if let until = model.suppressUnfollowUntil, Date() < until { return }
                model.followsLocation = false
            }
        }
    }
}

private extension View {
    func cameraChangeHandlers(
        model: LocationManagerModel,
        cameraHeading: Binding<CLLocationDirection>
    ) -> some View {
        modifier(CameraChangeModifier(model: model, cameraHeading: cameraHeading))
    }
}

// MARK: - UIKit Long-Press Capture (fixes Map gesture conflicts on newer iOS)
private struct LongPressCapture: UIViewRepresentable {
    let isActive: Bool
    var minimumPressDuration: TimeInterval = 0.5
    var allowableMovement: CGFloat = 12
    var onLongPress: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onLongPress: onLongPress) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let window = uiView.window else { return }
        context.coordinator.updateAttachment(active: isActive,
                                             on: window,
                                             allowableMovement: allowableMovement,
                                             minimumPressDuration: minimumPressDuration)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let onLongPress: (CGPoint) -> Void
        weak var window: UIWindow?
        var recognizer: UILongPressGestureRecognizer?

        init(onLongPress: @escaping (CGPoint) -> Void) { self.onLongPress = onLongPress }

        func updateAttachment(active: Bool,
                              on window: UIWindow,
                              allowableMovement: CGFloat,
                              minimumPressDuration: TimeInterval) {
            // Detach when not active
            if !active {
                if let r = recognizer, let w = self.window { w.removeGestureRecognizer(r) }
                recognizer = nil
                self.window = nil
                return
            }
            // Attach if needed
            if self.window === window, recognizer != nil { return }
            if let old = recognizer, let w = self.window { w.removeGestureRecognizer(old) }

            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            lp.minimumPressDuration = minimumPressDuration
            lp.allowableMovement = allowableMovement
            lp.cancelsTouchesInView = false
            lp.delaysTouchesBegan = false        // ✅ do not delay map touches
            lp.requiresExclusiveTouchType = false
            lp.delegate = self

            window.addGestureRecognizer(lp)
            self.window = window
            self.recognizer = lp
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began else { return }
            // Only handle single-finger long-press
            if recognizer.numberOfTouches != 1 { return }
            let pt = recognizer.location(in: window)
            onLongPress(pt)
        }

        // Allow MapKit gestures to proceed; prefer them when in conflict
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Don’t begin if there is multi-touch (pinch/rotate)
            if gestureRecognizer.numberOfTouches > 1 { return false }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            // Let Map’s pan/zoom/rotate win when competing
            return other is UIPinchGestureRecognizer ||
                other is UIRotationGestureRecognizer ||
                other is UIPanGestureRecognizer
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRequireFailureOf other: UIGestureRecognizer) -> Bool { false }
    }
}

// MARK: - UIKit Tap Capture for Polygon Mode
private struct TapCapture: UIViewRepresentable {
    let isActive: Bool
    var onTap: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the underlying MKMapView for this SwiftUI Map
        let root = uiView.window ?? uiView
        context.coordinator.lastRoot = root
        let mapView = Coordinator.findMapView(from: root)
        context.coordinator.updateAttachment(active: isActive, on: mapView)
        // If active but we still can’t find the map yet, retry shortly (SwiftUI view tree may still be mounting)
        if isActive, mapView == nil {
            context.coordinator.scheduleRetry()
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let onTap: (CGPoint) -> Void
        weak var mapView: MKMapView?
        var recognizer: UITapGestureRecognizer?
        weak var lastRoot: UIView?
        private var retryCount: Int = 0

        init(onTap: @escaping (CGPoint) -> Void) { self.onTap = onTap }

        static func findMapView(from start: UIView) -> MKMapView? {
            var root: UIView = start
            while let s = root.superview { root = s }
            return findMap(in: root)
        }
        private static func findMap(in view: UIView) -> MKMapView? {
            if let mv = view as? MKMapView { return mv }
            for sub in view.subviews {
                if let mv = findMap(in: sub) { return mv }
            }
            return nil
        }

        func updateAttachment(active: Bool, on mapView: MKMapView?) {
            if !active {
                if let r = recognizer, let mv = self.mapView { mv.removeGestureRecognizer(r) }
                recognizer = nil
                self.mapView = nil
                return
            }
            guard let mapView else { return }
            if self.mapView === mapView, recognizer != nil { return }
            if let old = recognizer, let mv = self.mapView { mv.removeGestureRecognizer(old) }

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.numberOfTapsRequired = 1
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delegate = self

            // Let tap co-exist with pan/zoom; MapKit will win on movement
            tap.requiresExclusiveTouchType = false

            mapView.addGestureRecognizer(tap)
            self.mapView = mapView
            self.recognizer = tap
            self.retryCount = 0
        }

        func scheduleRetry() {
            guard retryCount < 10 else { return }
            retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self else { return }
                guard let root = self.lastRoot else { return }
                let mapView = Self.findMapView(from: root)
                self.updateAttachment(active: true, on: mapView)
                if mapView == nil { self.scheduleRetry() } else { self.retryCount = 0 }
            }
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .recognized || recognizer.state == .ended else { return }
            if recognizer.numberOfTouches != 1 { return }
            guard let mapView = self.mapView else { return }
            let ptInMap = recognizer.location(in: mapView)
            let ptInWindow = mapView.convert(ptInMap, to: nil) // window-global
            onTap(ptInWindow)
        }

        // Keep MapKit responsive; allow simultaneous gesture recognition
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Only begin for single-finger taps; if movement occurs MapKit will take over
            gestureRecognizer.numberOfTouches <= 1
        }
    }
}

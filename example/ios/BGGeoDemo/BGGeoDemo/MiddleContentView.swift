import SwiftUI

enum ContentTab: String, CaseIterable {
    case map = "Map"
    case text = "Text"
}

struct MiddleContentView: View {
    @ObservedObject var model: LocationManagerModel
    @State private var tab: ContentTab = .map

    var body: some View {
        MapView(model: model)   // your Apple Map view
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

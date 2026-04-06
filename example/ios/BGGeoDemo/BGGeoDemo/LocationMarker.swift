import SwiftUI
import CoreLocation

struct LocationMarker: View {
    var course: CLLocationDirection?
    var color: Color = Color(red: 0x3A/255, green: 0x81/255, blue: 0xF5/255) // default = blue
    var size: CGFloat = 16
    
    var body: some View {
        LocationMarkerGlyph()
            .fill(color)                                              // use configurable color
            .overlay(                                                 // stroke above the fill
                LocationMarkerGlyph().stroke(.black, lineWidth: 1.0)
            )
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: course ?? 0))
            //.shadow(radius: 1, x: 0, y: 1)
    }
}

struct LocationMarkerGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // Tweak these two to fine-tune the look:
        let bottomWidthRatio: CGFloat = 0.65  // base width ≈ 65% of total width
        let cornerYRatio: CGFloat = 0.88      // bottom "corners" height (closer to bottom)
        let centerLiftRatio: CGFloat = 0.70   // bottom center lifted up (smaller = higher)

        let halfBase = (w * bottomWidthRatio) / 2
        let cornerY  = h * cornerYRatio
        let centerY  = h * centerLiftRatio   // <-- smaller than cornerY to push the center UP

        // Tip
        p.move(to: CGPoint(x: w/2, y: 0))
        // Right corner
        p.addLine(to: CGPoint(x: w/2 + halfBase, y: cornerY))
        // Bottom center (pushed UP into the shape)
        p.addLine(to: CGPoint(x: w/2, y: centerY))
        // Left corner
        p.addLine(to: CGPoint(x: w/2 - halfBase, y: cornerY))
        p.closeSubpath()
        return p
    }
}

import AppKit
import SwiftUI

/// The rounded panel behind the clock, in the chosen color and style.
struct BackgroundPanelView: View {
    var style: BackgroundStyle
    var color: Color
    var cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        switch style {
        case .vignette:
            // Slightly lighter in the middle, darker toward the edges.
            shape.fill(EllipticalGradient(
                stops: [
                    .init(color: color.mixed(with: .white, by: 0.07), location: 0),
                    .init(color: color, location: 0.55),
                    .init(color: color.mixed(with: .black, by: 0.55), location: 1)
                ],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadiusFraction: 0, endRadiusFraction: 0.75
            ))
        case .solid:
            shape.fill(color)
        case .transparent:
            Color.clear
        }
    }
}

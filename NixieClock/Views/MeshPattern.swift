import SwiftUI

/// The fine diamond anode mesh in front of a nixie tube's digits:
/// two sets of parallel lines at +60° and −60°.
struct MeshPattern: View {
    var spacing: CGFloat
    var lineWidth: CGFloat
    var color: Color

    var body: some View {
        Canvas { context, size in
            guard spacing > 0 else { return }
            let angle = CGFloat.pi / 3
            // Horizontal distance between neighbouring lines for the given perpendicular spacing.
            let step = spacing / sin(angle)
            // Horizontal run of one line across the full height.
            let run = size.height / tan(angle)

            var path = Path()
            var x = -run
            while x <= size.width + run {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + run, y: 0))
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + run, y: size.height))
                x += step
            }
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }
}

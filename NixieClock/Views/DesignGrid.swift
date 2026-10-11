import SwiftUI

extension View {
    /// Places this view at a frame given in design units, scaled to points by `s`.
    /// Use inside a `ZStack(alignment: .topLeading)` whose size is set by the caller.
    func placed(_ frame: CGRect, scale s: CGFloat) -> some View {
        self
            .frame(width: frame.width * s, height: frame.height * s)
            .offset(x: frame.minX * s, y: frame.minY * s)
    }
}

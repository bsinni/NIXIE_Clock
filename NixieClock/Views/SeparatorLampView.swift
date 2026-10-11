import SwiftUI

/// A small INS-1 style neon bulb used for the colons between digit pairs.
struct SeparatorLampView: View {
    var lit: Bool
    var glow: NixieGlow
    /// Points per design unit. The lamp is 18 × 40 design units.
    var s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.15), location: 0),
                    .init(color: .white.opacity(0.03), location: 0.4),
                    .init(color: .white.opacity(0.12), location: 1)
                ],
                startPoint: .leading, endPoint: .trailing
            ))

            if lit {
                Circle()
                    .fill(glow.color.opacity(0.5))
                    .frame(width: 16 * s, height: 16 * s)
                    .blur(radius: 6 * s)
            }

            Circle()
                .fill(lit ? glow.core : glow.core.opacity(0.18))
                .frame(width: 8 * s, height: 8 * s)
                .shadow(color: lit ? glow.color.opacity(0.9) : .clear, radius: 2 * s)
                .shadow(color: lit ? glow.color.opacity(0.7) : .clear, radius: 6 * s)

            Capsule().strokeBorder(.white.opacity(0.17), lineWidth: max(0.5, s))
        }
    }
}

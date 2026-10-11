import SwiftUI

/// The wooden plinth the tubes stand on: grain, a routed bevel line, the glow
/// reflecting on the top surface, and an optional brass nameplate.
struct WoodBaseView: View {
    var finish: WoodFinish
    var glow: NixieGlow
    /// Nameplate text, or nil to hide the plate.
    var plateText: String?
    /// Width of the base in design units (its height is always 118).
    var width: CGFloat
    /// Points per design unit.
    var s: CGFloat

    static let height: CGFloat = 118

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 12 * s, bottomLeadingRadius: 8 * s,
            bottomTrailingRadius: 8 * s, topTrailingRadius: 12 * s
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            shape.fill(LinearGradient(colors: finish.colors, startPoint: .top, endPoint: .bottom))

            WoodGrain(s: s)

            // Darker knots in the grain.
            knot(CGRect(x: width * 0.28 - 120, y: 77, width: 240, height: 16), opacity: 0.18)
            knot(CGRect(x: width * 0.74 - 90, y: 42, width: 180, height: 10), opacity: 0.14)

            // The tubes' glow reflected on the top surface.
            EllipticalGradient(
                colors: [glow.color.opacity(0.2), glow.color.opacity(0)],
                center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
            )
            .placed(CGRect(x: width * 0.2, y: -64, width: width * 0.6, height: 128), scale: s)

            // Routed edge line along the top.
            Rectangle().fill(.black.opacity(0.35))
                .placed(CGRect(x: 0, y: 24, width: width, height: 2), scale: s)
            Rectangle().fill(Color(red: 1, green: 220 / 255, blue: 180 / 255).opacity(0.12))
                .placed(CGRect(x: 0, y: 26, width: width, height: 1), scale: s)

            // Inner shading: a light top edge and darkening toward the bottom.
            Rectangle().fill(Color(red: 1, green: 225 / 255, blue: 190 / 255).opacity(0.22))
                .placed(CGRect(x: 6, y: 0, width: width - 12, height: 2), scale: s)
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0.7),
                    .init(color: .black.opacity(0.45), location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
        .frame(width: width * s, height: Self.height * s)
        .clipShape(shape)
        .overlay(alignment: .top) {
            if let plateText {
                Nameplate(text: plateText, s: s)
                    .padding(.top, 50 * s)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 7 * s, y: 8 * s)
        .shadow(color: .black.opacity(0.7), radius: 25 * s, y: 34 * s)
    }

    private func knot(_ frame: CGRect, opacity: Double) -> some View {
        EllipticalGradient(
            colors: [.black.opacity(opacity), .black.opacity(0)],
            center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
        )
        .placed(frame, scale: s)
    }
}

/// Horizontal wood grain: gently wavy lines of varying weight, generated
/// deterministically so the grain doesn't change between redraws.
private struct WoodGrain: View {
    var s: CGFloat

    var body: some View {
        Canvas { context, size in
            let unit = s
            var y = 2 * unit
            var i = 0
            while y < size.height {
                let amplitude = (0.5 + Double((i * 37) % 10) / 10) * unit
                let frequency = (0.004 + Double((i * 13) % 7) * 0.0008) / unit
                let phase = Double((i * 53) % 17)

                var path = Path()
                path.move(to: CGPoint(x: 0, y: y + amplitude * sin(phase)))
                var x = 6 * unit
                while x <= size.width + 6 * unit {
                    path.addLine(to: CGPoint(x: x, y: y + amplitude * sin(x * frequency + phase)))
                    x += 6 * unit
                }

                let light = i % 5 == 2
                let color: Color = light
                    ? Color(red: 1, green: 230 / 255, blue: 200 / 255).opacity(0.06)
                    : .black.opacity(i % 3 == 0 ? 0.16 : 0.08)
                context.stroke(path, with: .color(color), lineWidth: (i % 4 == 0 ? 1.4 : 0.8) * unit)

                y += (3 + Double((i * 29) % 5)) * unit
                i += 1
            }
        }
    }
}

/// Engraved brass plate with a screw at each end.
private struct Nameplate: View {
    var text: String
    var s: CGFloat

    var body: some View {
        HStack(spacing: 14 * s) {
            screw
            Text(text)
                .font(.system(size: 15 * s, weight: .semibold, design: .serif))
                .tracking(2.7 * s)
                .foregroundStyle(Color(red: 0x3F / 255, green: 0x2C / 255, blue: 0x0C / 255))
                .shadow(color: Color(red: 1, green: 240 / 255, blue: 200 / 255).opacity(0.45), radius: 0, y: s)
                .lineLimit(1)
                .fixedSize()
            screw
        }
        .padding(.vertical, 9 * s)
        .padding(.horizontal, 14 * s)
        .background(
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color(red: 0xE4 / 255, green: 0xC5 / 255, blue: 0x7E / 255), location: 0),
                        .init(color: Color(red: 0xB1 / 255, green: 0x8A / 255, blue: 0x42 / 255), location: 0.55),
                        .init(color: Color(red: 0xD1 / 255, green: 0xAB / 255, blue: 0x62 / 255), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 1, green: 250 / 255, blue: 220 / 255).opacity(0.6))
                        .frame(height: max(0.5, s))
                        .padding(.horizontal, 3 * s)
                }
                .shadow(color: .black.opacity(0.5), radius: 2 * s, y: 2 * s)
        )
    }

    private var screw: some View {
        Circle()
            .fill(RadialGradient(
                colors: [
                    Color(red: 0xF3 / 255, green: 0xDC / 255, blue: 0xA0 / 255),
                    Color(red: 0x8A / 255, green: 0x6A / 255, blue: 0x2E / 255)
                ],
                center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: 5 * s
            ))
            .overlay(Circle().strokeBorder(Color(red: 60 / 255, green: 40 / 255, blue: 10 / 255).opacity(0.4), lineWidth: max(0.5, s)))
            .frame(width: 7 * s, height: 7 * s)
    }
}

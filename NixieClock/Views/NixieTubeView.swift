import SwiftUI

/// One nixie tube: glass envelope, unlit "ghost" cathodes, the lit digit with its glow,
/// the anode mesh, reflections, and a metal socket with a brass ring.
///
/// All geometry is laid out on a 112 × 310 design grid (matching the mockup) and
/// multiplied by a scale factor, so the tube stays crisp at any size.
struct NixieTubeView: View {
    /// The lit digit, or nil for a tube with nothing lit.
    var digit: Int?
    var glow: NixieGlow
    /// Crossfade between digits. Costs about 1% CPU per clock while ticking.
    var animated = true

    static let designSize = CGSize(width: 112, height: 310)

    var body: some View {
        GeometryReader { proxy in
            let s = min(
                proxy.size.width / Self.designSize.width,
                proxy.size.height / Self.designSize.height
            )
            TubeLayers(digit: digit, glow: glow, animated: animated, s: s)
                .frame(width: Self.designSize.width * s, height: Self.designSize.height * s)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(Self.designSize, contentMode: .fit)
    }
}

// MARK: - Layers

private struct TubeLayers: View {
    let digit: Int?
    let glow: NixieGlow
    let animated: Bool
    /// Points per design unit.
    let s: CGFloat

    // Design-grid frames (x, y, width, height) on the 112 × 310 grid.
    private let tipFrame = CGRect(x: 50, y: 0, width: 12, height: 16)
    private let glassFrame = CGRect(x: 4, y: 12, width: 104, height: 258)
    private let socketFrame = CGRect(x: 0, y: 264, width: 112, height: 46)
    private let ringFrame = CGRect(x: 6, y: 264, width: 100, height: 6)

    /// Where the cathodes sit inside the glass.
    private let cathodeFrame = CGRect(x: 6, y: 44, width: 92, height: 190)

    // The tube is drawn as three stacked layers. The back and front never change
    // between ticks, so each is flattened into one GPU layer; animation frames then
    // only redraw the lit digit in the middle.
    var body: some View {
        ZStack(alignment: .topLeading) {
            back
            place(litDigitLayer, glassFrame)
            front
        }
    }

    /// Exhaust tip, glass body, ambient tint, and the unlit ghost digits.
    private var back: some View {
        ZStack(alignment: .topLeading) {
            place(tip, tipFrame)
            place(glassBack, glassFrame)
        }
        .frame(width: NixieTubeView.designSize.width * s, height: NixieTubeView.designSize.height * s, alignment: .topLeading)
        .drawingGroup()
    }

    /// Mesh, reflections, glass edge, and the socket.
    private var front: some View {
        let margin = 12 * s // room for the socket's shadow
        return ZStack(alignment: .topLeading) {
            place(glassFront, glassFrame)
            place(socket, socketFrame)
            place(ring, ringFrame)
        }
        .frame(width: NixieTubeView.designSize.width * s, height: NixieTubeView.designSize.height * s, alignment: .topLeading)
        .padding(margin)
        .drawingGroup()
        .padding(-margin)
    }

    // MARK: Exhaust tip

    private var tip: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 6 * s, bottomLeadingRadius: 3 * s,
            bottomTrailingRadius: 3 * s, topTrailingRadius: 6 * s
        )
        .fill(LinearGradient(
            colors: [.white.opacity(0.2), .white.opacity(0.04)],
            startPoint: .leading, endPoint: .trailing
        ))
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 6 * s, bottomLeadingRadius: 3 * s,
                bottomTrailingRadius: 3 * s, topTrailingRadius: 6 * s
            )
            .strokeBorder(.white.opacity(0.18), lineWidth: max(0.5, s))
        )
    }

    // MARK: Glass envelope and everything inside it

    private var glassShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 52 * s, bottomLeadingRadius: 12 * s,
            bottomTrailingRadius: 12 * s, topTrailingRadius: 52 * s
        )
    }

    private var glassBack: some View {
        ZStack(alignment: .topLeading) {
            // Glass body: bright at the curved edges, clear through the middle.
            glassShape.fill(LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.13), location: 0),
                    .init(color: .white.opacity(0.03), location: 0.18),
                    .init(color: .white.opacity(0.0), location: 0.5),
                    .init(color: .white.opacity(0.03), location: 0.82),
                    .init(color: .white.opacity(0.14), location: 1)
                ],
                startPoint: .leading, endPoint: .trailing
            ))

            // Ambient tint: the glow lighting up the gas inside the tube.
            if digit != nil {
                EllipticalGradient(
                    colors: [glow.color.opacity(0.16), glow.color.opacity(0)],
                    center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
                )
                .frame(width: 104 * 1.4 * s, height: 258 * 0.9 * s)
                .position(x: 52 * s, y: 258 * 0.52 * s)
            }

            place(ghostDigits, cathodeFrame)
        }
        .clipShape(glassShape)
    }

    private var glassFront: some View {
        ZStack(alignment: .topLeading) {
            place(
                MeshPattern(
                    spacing: 7 * s,
                    lineWidth: max(0.5, s),
                    color: Color(red: 130 / 255, green: 110 / 255, blue: 90 / 255).opacity(0.16)
                )
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 42 * s, bottomLeadingRadius: 6 * s,
                    bottomTrailingRadius: 6 * s, topTrailingRadius: 42 * s
                )),
                CGRect(x: 6, y: 30, width: 92, height: 216)
            )

            // Reflection streaks on the curved glass.
            place(
                Capsule().fill(LinearGradient(
                    colors: [.white.opacity(0.4), .white.opacity(0)],
                    startPoint: .top, endPoint: .bottom
                )),
                CGRect(x: 12, y: 36, width: 7, height: 150)
            )
            place(
                Capsule().fill(LinearGradient(
                    colors: [.white.opacity(0.22), .white.opacity(0)],
                    startPoint: .top, endPoint: .bottom
                )),
                CGRect(x: 91, y: 60, width: 3, height: 103)
            )

            // Darkening toward the base, where the glass meets the socket.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0.75),
                    .init(color: .black.opacity(0.35), location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
        .clipShape(glassShape)
        .overlay(glassShape.strokeBorder(.white.opacity(0.17), lineWidth: max(0.5, s)))
    }

    // MARK: Cathodes (ghost digits + lit digit)

    /// Stacking order of the cathodes, back to front, as in a real IN-14 style tube.
    private static let cathodeOrder = [1, 6, 2, 7, 5, 0, 4, 9, 8, 3]

    private var ghostDigits: some View {
        ZStack {
            ForEach(Self.cathodeOrder, id: \.self) { n in
                numeral(n)
                    .foregroundStyle(Color(red: 170 / 255, green: 150 / 255, blue: 130 / 255).opacity(0.09))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The lit digit, clipped to the glass. When the digit changes, the old cathode
    /// fades out as the new one fades in. It's a pre-rendered image, so the
    /// animation never has to redraw the blurs.
    private var litDigitLayer: some View {
        ZStack(alignment: .topLeading) {
            place(
                ZStack {
                    if let digit {
                        Image(nsImage: LitDigitCache.image(digit: digit, glow: glow, s: s))
                            .id(digit)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity),
                cathodeFrame
            )
        }
        .frame(width: glassFrame.width * s, height: glassFrame.height * s, alignment: .topLeading)
        .clipShape(glassShape)
        .animation(animated ? .easeOut(duration: 0.12) : nil, value: digit)
    }

    private func numeral(_ n: Int) -> some View {
        LitDigitView.numeral(n, s: s)
    }

    // MARK: Socket

    private var socket: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 8 * s, bottomLeadingRadius: 4 * s,
            bottomTrailingRadius: 4 * s, topTrailingRadius: 8 * s
        )
        return shape
            .fill(LinearGradient(
                stops: [
                    .init(color: Color(red: 0x3A / 255, green: 0x36 / 255, blue: 0x33 / 255), location: 0),
                    .init(color: Color(red: 0x1A / 255, green: 0x18 / 255, blue: 0x17 / 255), location: 0.4),
                    .init(color: Color(red: 0x0B / 255, green: 0x0A / 255, blue: 0x0A / 255), location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay(alignment: .top) {
                // Thin highlight along the socket's top edge.
                Rectangle()
                    .fill(.white.opacity(0.16))
                    .frame(height: max(0.5, s))
                    .padding(.horizontal, 8 * s)
            }
            .shadow(color: .black.opacity(0.6), radius: 5 * s, y: 4 * s)
    }

    private var ring: some View {
        Capsule().fill(LinearGradient(
            colors: [
                Color(red: 0xD6 / 255, green: 0xB4 / 255, blue: 0x6A / 255),
                Color(red: 0x7D / 255, green: 0x5F / 255, blue: 0x28 / 255)
            ],
            startPoint: .top, endPoint: .bottom
        ))
    }

    // MARK: Helpers

    /// Places a view at a design-grid frame, scaled to points.
    private func place(_ view: some View, _ frame: CGRect) -> some View {
        view.placed(frame, scale: s)
    }
}

// MARK: - Lit digit

/// A lit digit: halo built from blurred copies, widest first, then the hot core on top.
/// Rendered once into an image by `LitDigitCache` so digit changes don't redraw the blurs.
private struct LitDigitView: View {
    let digit: Int
    let glow: NixieGlow
    let s: CGFloat

    /// Room around the numeral so the widest blur isn't cut off (≥ 2 × its radius).
    static let blurMargin: CGFloat = 44

    var body: some View {
        ZStack {
            Self.numeral(digit, s: s).foregroundStyle(glow.color).blur(radius: 20 * s).opacity(0.55)
            Self.numeral(digit, s: s).foregroundStyle(glow.color).blur(radius: 8 * s).opacity(0.85)
            Self.numeral(digit, s: s).foregroundStyle(glow.color).blur(radius: 2.5 * s)
            Self.numeral(digit, s: s).foregroundStyle(glow.core)
        }
        .padding(Self.blurMargin * s)
    }

    static func numeral(_ n: Int, s: CGFloat) -> some View {
        // Thin, slightly condensed numerals. Swap in a bundled nixie-style font later.
        Text(String(n))
            .font(.system(size: 176 * s, weight: .ultraLight))
            .scaleEffect(x: 0.85, y: 1)
            .fixedSize()
    }
}

/// Pre-rendered lit digits, keyed by digit, color, and size.
private enum LitDigitCache {
    private static var images: [String: NSImage] = [:]
    /// Resizing a window creates new sizes; start over rather than grow without bound.
    private static let limit = 160

    static func image(digit: Int, glow: NixieGlow, s: CGFloat) -> NSImage {
        let key = "\(digit)|\(glow.key)|\(s)"
        if let cached = images[key] { return cached }

        let renderer = ImageRenderer(content: LitDigitView(digit: digit, glow: glow, s: s))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        if images.count >= limit { images.removeAll() }
        images[key] = image
        return image
    }
}

// MARK: - Previews

#Preview("Colors") {
    HStack(spacing: 14) {
        ForEach(Array(NixieColor.allCases.enumerated()), id: \.element) { index, preset in
            NixieTubeView(digit: index + 3, glow: NixieGlow(preset.color))
        }
        NixieTubeView(digit: nil, glow: NixieGlow(NixieColor.nixieOrange.color))
    }
    .padding(40)
    .frame(width: 1000, height: 420)
    .background(Color(red: 0.05, green: 0.045, blue: 0.045))
}

#Preview("All digits") {
    HStack(spacing: 10) {
        ForEach(0..<10) { n in
            NixieTubeView(digit: n, glow: NixieGlow(NixieColor.nixieOrange.color))
        }
    }
    .padding(30)
    .frame(width: 1100, height: 340)
    .background(Color(red: 0.05, green: 0.045, blue: 0.045))
}

#Preview("Small") {
    HStack(spacing: 6) {
        NixieTubeView(digit: 1, glow: NixieGlow(NixieColor.iceBlue.color))
        NixieTubeView(digit: 2, glow: NixieGlow(NixieColor.iceBlue.color))
    }
    .padding(12)
    .frame(width: 120, height: 120)
    .background(.black)
}

import AppKit
import SwiftUI

/// Preset glow colors offered as swatches in settings.
enum NixieColor: String, CaseIterable, Identifiable, Codable {
    case nixieOrange, neonRed, iceBlue, phosphorGreen, violet, warmWhite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .nixieOrange: "Nixie Orange"
        case .neonRed: "Neon Red"
        case .iceBlue: "Ice Blue"
        case .phosphorGreen: "Phosphor Green"
        case .violet: "Violet"
        case .warmWhite: "Warm White"
        }
    }

    var hex: String {
        switch self {
        case .nixieOrange: "#FF6A00"
        case .neonRed: "#FF2D55"
        case .iceBlue: "#3DA9FF"
        case .phosphorGreen: "#39FF88"
        case .violet: "#B266FF"
        case .warmWhite: "#FFE2B8"
        }
    }

    var color: Color { Color(hex: hex) ?? .orange }
}

extension Color {
    /// Parses `#RRGGBB` or `RRGGBB`. Returns nil for anything else.
    init?(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension NSColor {
    /// `#RRGGBB` in sRGB, ignoring alpha.
    var hexString: String {
        let c = usingColorSpace(.sRGB) ?? .black
        func byte(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(c.redComponent), byte(c.greenComponent), byte(c.blueComponent))
    }
}

extension Color {
    /// This color blended toward `other` by `fraction` (0 = unchanged, 1 = `other`).
    func mixed(with other: NSColor, by fraction: CGFloat) -> Color {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return Color(nsColor: ns.blended(withFraction: fraction, of: other) ?? ns)
    }
}

/// The colors a lit tube needs, derived from one chosen glow color.
struct NixieGlow {
    /// The glow itself: used for the halo and the tint inside the glass.
    let color: Color
    /// The hot core of the lit digit: the glow color pushed toward white.
    let core: Color
    /// Identifies the color, for caching rendered digits.
    let key: String

    init(_ color: Color) {
        self.color = color
        core = color.mixed(with: .white, by: 0.3)
        key = NSColor(color).hexString
    }
}

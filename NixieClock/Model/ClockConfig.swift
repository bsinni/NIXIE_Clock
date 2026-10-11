import SwiftUI

/// Everything that describes one clock's appearance and behavior.
/// Phase 5 persists a list of these and edits them from the menu bar.
struct ClockConfig: Codable, Identifiable, Equatable {
    var id = UUID()
    /// IANA identifier such as "Asia/Tokyo"; nil follows the system time zone.
    var timeZoneID: String?
    var colorHex = NixieColor.nixieOrange.hex
    var backgroundHex = "#0C0B0B"
    var backgroundOpacity = 1.0
    var backgroundStyle = BackgroundStyle.vignette
    var wood = WoodFinish.walnut
    var use24h = true
    var showSeconds = true
    var blinkSeparators = true
    var showPlate = true
    /// The window's last frame in screen coordinates; nil places it at the default spot.
    var frame: CGRect?
    /// Locked clocks ignore the mouse, so clicks pass through to the desktop.
    var locked = false

    init() {}

    // Decode field by field with defaults, so settings saved by an older version
    // still load after new fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ClockConfig()
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? d.id
        timeZoneID = try c.decodeIfPresent(String.self, forKey: .timeZoneID)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? d.colorHex
        backgroundHex = try c.decodeIfPresent(String.self, forKey: .backgroundHex) ?? d.backgroundHex
        backgroundOpacity = try c.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? d.backgroundOpacity
        backgroundStyle = (try? c.decodeIfPresent(BackgroundStyle.self, forKey: .backgroundStyle)) ?? d.backgroundStyle
        wood = (try? c.decodeIfPresent(WoodFinish.self, forKey: .wood)) ?? d.wood
        use24h = try c.decodeIfPresent(Bool.self, forKey: .use24h) ?? d.use24h
        showSeconds = try c.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? d.showSeconds
        blinkSeparators = try c.decodeIfPresent(Bool.self, forKey: .blinkSeparators) ?? d.blinkSeparators
        showPlate = try c.decodeIfPresent(Bool.self, forKey: .showPlate) ?? d.showPlate
        frame = try c.decodeIfPresent(CGRect.self, forKey: .frame)
        locked = try c.decodeIfPresent(Bool.self, forKey: .locked) ?? d.locked
    }

    var timeZone: TimeZone {
        timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    var glowColor: Color {
        Color(hex: colorHex) ?? NixieColor.nixieOrange.color
    }

    var backgroundColor: Color {
        (Color(hex: backgroundHex) ?? .black).opacity(backgroundOpacity)
    }
}

enum BackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case vignette, solid, transparent

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}

enum WoodFinish: String, Codable, CaseIterable, Identifiable {
    case walnut, oak, ebony

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    /// Top, middle, and bottom colors of the plinth.
    var colors: [Color] {
        switch self {
        case .walnut: ["#6E4224", "#4A2914", "#2B1609"].compactMap(Color.init(hex:))
        case .oak: ["#BD8A56", "#94663A", "#6A4423"].compactMap(Color.init(hex:))
        case .ebony: ["#2E2420", "#1D1613", "#0E0A08"].compactMap(Color.init(hex:))
        }
    }
}

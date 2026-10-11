import SwiftUI

/// The live clock: ticks once per second and scales the clock face to fit its space.
struct NixieClockView: View {
    var config = ClockConfig()

    // Start the schedule on the next whole second so ticks line up with the clock.
    private let schedule = PeriodicTimelineSchedule(
        from: Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.up)),
        by: 1
    )

    var body: some View {
        TimelineView(schedule) { context in
            GeometryReader { proxy in
                let design = ClockLayout(showSeconds: config.showSeconds).size
                let s = min(proxy.size.width / design.width, proxy.size.height / design.height)
                ClockFaceView(config: config, date: context.date, s: s)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// Design-unit measurements for the whole clock. Tubes are 112 × 310; everything
/// else is sized to match the mockup.
struct ClockLayout {
    static let tubeSize = CGSize(width: 112, height: 310)
    static let lampSize = CGSize(width: 18, height: 40)
    static let lampColumnWidth: CGFloat = 26
    static let gap: CGFloat = 14
    static let rowInset: CGFloat = 56
    static let baseOverlap: CGFloat = 10
    static let panelInsets = EdgeInsets(top: 40, leading: 48, bottom: 60, trailing: 48)

    let tubeCount: Int
    var separatorCount: Int { tubeCount / 2 - 1 }

    init(showSeconds: Bool) {
        tubeCount = showSeconds ? 6 : 4
    }

    /// Width of the tube row, which is also the width of the wooden base.
    var rowWidth: CGFloat {
        CGFloat(tubeCount) * Self.tubeSize.width
            + CGFloat(separatorCount) * Self.lampColumnWidth
            + CGFloat(tubeCount + separatorCount - 1) * Self.gap
            + 2 * Self.rowInset
    }

    var assemblyHeight: CGFloat {
        Self.tubeSize.height + WoodBaseView.height - Self.baseOverlap
    }

    /// The full clock, including the background panel, in design units.
    var size: CGSize {
        CGSize(
            width: rowWidth + Self.panelInsets.leading + Self.panelInsets.trailing,
            height: assemblyHeight + Self.panelInsets.top + Self.panelInsets.bottom
        )
    }
}

/// The clock face for one instant, drawn at `s` points per design unit.
struct ClockFaceView: View {
    var config: ClockConfig
    var date: Date
    var s: CGFloat

    private enum Item {
        case tube(digit: Int, frame: CGRect)
        case lamp(frame: CGRect)
    }

    var body: some View {
        let layout = ClockLayout(showSeconds: config.showSeconds)
        let glow = NixieGlow(config.glowColor)
        let time = ClockTime(date: date, config: config)
        let origin = CGPoint(x: ClockLayout.panelInsets.leading, y: ClockLayout.panelInsets.top)
        let items = Self.items(for: time.digitGroups, origin: origin)
        let lampsLit = !config.blinkSeparators || time.second % 2 == 0

        ZStack(alignment: .topLeading) {
            BackgroundPanelView(
                style: config.backgroundStyle,
                color: config.backgroundColor,
                cornerRadius: 28 * s
            )

            WoodBaseView(
                finish: config.wood,
                glow: glow,
                plateText: config.showPlate ? time.plateText : nil,
                width: layout.rowWidth,
                s: s
            )
            .placed(
                CGRect(
                    x: origin.x,
                    y: origin.y + ClockLayout.tubeSize.height - ClockLayout.baseOverlap,
                    width: layout.rowWidth,
                    height: WoodBaseView.height
                ),
                scale: s
            )

            ForEach(items.indices, id: \.self) { index in
                switch items[index] {
                case let .tube(digit, frame):
                    NixieTubeView(digit: digit, glow: glow).placed(frame, scale: s)
                case let .lamp(frame):
                    SeparatorLampView(lit: lampsLit, glow: glow, s: s).placed(frame, scale: s)
                }
            }
        }
        .frame(width: layout.size.width * s, height: layout.size.height * s, alignment: .topLeading)
    }

    /// Tubes and separator lamps, left to right, in design units.
    private static func items(for groups: [[Int]], origin: CGPoint) -> [Item] {
        var items: [Item] = []
        var x = origin.x + ClockLayout.rowInset
        for (index, group) in groups.enumerated() {
            if index > 0 {
                let lampX = x + (ClockLayout.lampColumnWidth - ClockLayout.lampSize.width) / 2
                // Two lamps centered on the digits (the digit area's middle is 151 units down the tube).
                items.append(.lamp(frame: CGRect(origin: CGPoint(x: lampX, y: origin.y + 88), size: ClockLayout.lampSize)))
                items.append(.lamp(frame: CGRect(origin: CGPoint(x: lampX, y: origin.y + 174), size: ClockLayout.lampSize)))
                x += ClockLayout.lampColumnWidth + ClockLayout.gap
            }
            for digit in group {
                items.append(.tube(digit: digit, frame: CGRect(origin: CGPoint(x: x, y: origin.y), size: ClockLayout.tubeSize)))
                x += ClockLayout.tubeSize.width + ClockLayout.gap
            }
        }
        return items
    }
}

/// The time as the clock displays it: digit groups, seconds, and nameplate text.
struct ClockTime {
    let digitGroups: [[Int]]
    let second: Int
    let plateText: String

    init(date: Date, config: ClockConfig) {
        let timeZone = config.timeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour24 = c.hour ?? 0
        let minute = c.minute ?? 0
        second = c.second ?? 0

        let hour = config.use24h ? hour24 : (hour24 % 12 == 0 ? 12 : hour24 % 12)
        var values = [hour, minute]
        if config.showSeconds { values.append(second) }
        digitGroups = values.map { [$0 / 10, $0 % 10] }

        let city = config.timeZoneID?
            .split(separator: "/").last
            .map { $0.replacingOccurrences(of: "_", with: " ") }
            ?? "Local time"
        var parts = [city, Self.gmtOffset(timeZone.secondsFromGMT(for: date))]
        if !config.use24h { parts.append(hour24 < 12 ? "AM" : "PM") }
        plateText = parts.joined(separator: " · ").uppercased()
    }

    /// "GMT", "GMT+9", "GMT-7", "GMT+5:30".
    static func gmtOffset(_ seconds: Int) -> String {
        guard seconds != 0 else { return "GMT" }
        let sign = seconds < 0 ? "-" : "+"
        let hours = abs(seconds) / 3600
        let minutes = abs(seconds) % 3600 / 60
        return minutes == 0
            ? "GMT\(sign)\(hours)"
            : String(format: "GMT%@%d:%02d", sign, hours, minutes)
    }
}

#Preview("Seconds") {
    NixieClockView()
        .frame(width: 620, height: 310)
}

#Preview("Tokyo, 12h, oak, no seconds") {
    var config = ClockConfig()
    config.timeZoneID = "Asia/Tokyo"
    config.use24h = false
    config.showSeconds = false
    config.wood = .oak
    config.colorHex = NixieColor.iceBlue.hex
    return NixieClockView(config: config)
        .frame(width: 460, height: 320)
}

import SwiftUI

/// The clock: a row of nixie tubes showing HH:MM:SS.
/// Phase 3 adds the separator lamps, wooden base, and nameplate.
struct NixieClockView: View {
    var timeZone: TimeZone = .current
    var glow = NixieGlow(NixieColor.nixieOrange.color)

    // Start the schedule on the next whole second so ticks line up with the clock.
    private let schedule = PeriodicTimelineSchedule(
        from: Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.up)),
        by: 1
    )

    var body: some View {
        TimelineView(schedule) { context in
            GeometryReader { proxy in
                let groups = digitGroups(for: context.date)
                HStack(spacing: proxy.size.height * 0.08) {
                    ForEach(groups.indices, id: \.self) { i in
                        HStack(spacing: proxy.size.height * 0.03) {
                            ForEach(groups[i].indices, id: \.self) { j in
                                NixieTubeView(digit: groups[i][j], glow: glow)
                            }
                        }
                    }
                }
                .padding(proxy.size.height * 0.08)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: proxy.size.height * 0.1)
                        .fill(Color(red: 0.05, green: 0.045, blue: 0.045))
                )
            }
        }
    }

    /// [[h, h], [m, m], [s, s]] for the date in this clock's time zone.
    private func digitGroups(for date: Date) -> [[Int]] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        return [c.hour ?? 0, c.minute ?? 0, c.second ?? 0].map { [$0 / 10, $0 % 10] }
    }
}

#Preview {
    NixieClockView()
        .frame(width: 520, height: 220)
}

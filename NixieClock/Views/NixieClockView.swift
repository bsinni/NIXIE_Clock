import SwiftUI

/// Phase 1 placeholder: plain glowing digits. Replaced by real tubes in Phases 2–3.
struct NixieClockView: View {
    var timeZone: TimeZone = .current

    // Start the schedule on the next whole second so ticks line up with the clock.
    private let schedule = PeriodicTimelineSchedule(
        from: Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.up)),
        by: 1
    )

    var body: some View {
        TimelineView(schedule) { context in
            GeometryReader { proxy in
                Text(timeString(for: context.date))
                    .font(.system(size: proxy.size.height * 0.55, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(Color(red: 1, green: 0.62, blue: 0.3))
                    .shadow(color: .orange, radius: 6)
                    .shadow(color: .orange.opacity(0.6), radius: 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: proxy.size.height * 0.12)
                            .fill(Color(red: 0.05, green: 0.045, blue: 0.045))
                    )
            }
        }
    }

    private func timeString(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        return String(format: "%02d:%02d:%02d", c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}

#Preview {
    NixieClockView()
        .frame(width: 520, height: 180)
}

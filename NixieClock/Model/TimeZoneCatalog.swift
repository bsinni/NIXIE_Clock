import Foundation

/// One choice in the time zone picker. A nil identifier means the system time zone.
struct TimeZoneOption: Identifiable, Hashable {
    let identifier: String?
    let city: String
    /// e.g. "Asia/Tokyo" or "System setting".
    let detail: String
    /// e.g. "Japan Standard Time"; searched but not shown.
    let longName: String

    var id: String { identifier ?? "local" }

    var offsetText: String {
        TimeZoneCatalog.offsetText(for: identifier)
    }
}

enum TimeZoneCatalog {
    static let local = TimeZoneOption(
        identifier: nil, city: "Local time", detail: "System setting", longName: "local system current"
    )

    static let all: [TimeZoneOption] = TimeZone.knownTimeZoneIdentifiers
        .compactMap { id -> TimeZoneOption? in
            guard let zone = TimeZone(identifier: id) else { return nil }
            return TimeZoneOption(
                identifier: id,
                city: city(for: id),
                detail: id.replacingOccurrences(of: "_", with: " "),
                longName: zone.localizedName(for: .generic, locale: .current) ?? ""
            )
        }
        .sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }

    /// Matches city, identifier, or long name; local time comes first when it matches.
    static func search(_ query: String) -> [TimeZoneOption] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        func matches(_ o: TimeZoneOption) -> Bool {
            o.city.localizedCaseInsensitiveContains(q)
                || o.detail.localizedCaseInsensitiveContains(q)
                || o.longName.localizedCaseInsensitiveContains(q)
        }
        // Cities that start with the query rank above other matches.
        let found = all.filter(matches)
        let starts = found.filter { $0.city.lowercased().hasPrefix(q.lowercased()) }
        let rest = found.filter { !$0.city.lowercased().hasPrefix(q.lowercased()) }
        return (matches(local) ? [local] : []) + starts + rest
    }

    /// "Tokyo" for "Asia/Tokyo", "Local time" for nil.
    static func city(for identifier: String?) -> String {
        guard let identifier else { return local.city }
        return identifier
            .split(separator: "/").last
            .map { $0.replacingOccurrences(of: "_", with: " ") }
            ?? identifier
    }

    static func offsetText(for identifier: String?, at date: Date = .now) -> String {
        let zone = identifier.flatMap(TimeZone.init(identifier:)) ?? .current
        return gmtOffset(zone.secondsFromGMT(for: date))
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

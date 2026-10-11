import Foundation
import Observation

/// All clocks and their settings, saved as JSON in UserDefaults.
@Observable
final class ClockStore {
    private static let defaultsKey = "clocks"

    private(set) var clocks: [ClockConfig]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([ClockConfig].self, from: data),
           !saved.isEmpty {
            clocks = saved
        } else {
            clocks = [ClockConfig()]
        }
    }

    func clock(_ id: UUID) -> ClockConfig? {
        clocks.first { $0.id == id }
    }

    /// Changes one clock's settings and saves.
    func update(_ id: UUID, _ change: (inout ClockConfig) -> Void) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        var config = clocks[index]
        change(&config)
        guard config != clocks[index] else { return }
        clocks[index] = config
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(clocks) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}

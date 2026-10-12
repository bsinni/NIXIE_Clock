import AppKit

/// Keeps one desktop window per clock in the store, and is the single place
/// settings changes go through so windows stay in step with them.
final class ClockManager {
    let store: ClockStore
    let colorPanel = ColorPanelCoordinator()
    private var windowControllers: [UUID: ClockWindowController] = [:]

    init(store: ClockStore) {
        self.store = store
    }

    func openAllWindows() {
        store.clocks.forEach { openWindow(for: $0.id) }
    }

    /// Adds a clock with default settings, placed just off the others. Returns its id.
    @discardableResult
    func addClock() -> UUID {
        var config = ClockConfig()
        config.frame = ClockWindowController.defaultFrame(
            for: config,
            offset: CGFloat(store.clocks.count % 8) * 36
        )
        store.add(config)
        openWindow(for: config.id)
        return config.id
    }

    func removeClock(_ id: UUID) {
        guard store.clocks.count > 1 else { return }
        windowControllers.removeValue(forKey: id)?.close()
        store.remove(id)
    }

    /// Changes one clock's settings and updates its window.
    func update(_ id: UUID, _ change: (inout ClockConfig) -> Void) {
        store.update(id, change)
        windowControllers[id]?.applyConfig()
    }

    func setScale(_ scale: CGFloat, for id: UUID) {
        windowControllers[id]?.setScale(scale)
    }

    func resetFrame(for id: UUID) {
        windowControllers[id]?.resetFrame()
    }

    private func openWindow(for id: UUID) {
        let controller = ClockWindowController(clockID: id, store: store)
        controller.showWindow(nil)
        windowControllers[id] = controller
    }
}

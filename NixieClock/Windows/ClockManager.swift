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

    /// Opens the settings window, optionally with one clock selected.
    func showSettings(selecting id: UUID? = nil) {
        settingsWindow.show(selecting: id)
    }

    private lazy var settingsWindow = SettingsWindowController(manager: self)

    private func openWindow(for id: UUID) {
        let controller = ClockWindowController(clockID: id, store: store) { [weak self] in
            self?.contextMenu(for: id) ?? NSMenu()
        }
        controller.showWindow(nil)
        windowControllers[id] = controller
    }

    /// The right-click menu on a clock window.
    private func contextMenu(for id: UUID) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(actionMenuItem("Settings…") { [weak self] in self?.showSettings(selecting: id) })
        menu.addItem(actionMenuItem("Add Clock") { [weak self] in
            guard let self else { return }
            self.showSettings(selecting: self.addClock())
        })
        let onTop = actionMenuItem("Keep on Top") { [weak self] in
            self?.update(id) { $0.keepOnTop.toggle() }
        }
        onTop.state = store.clock(id)?.keepOnTop == true ? .on : .off
        menu.addItem(onTop)
        menu.addItem(.separator())
        let remove = actionMenuItem("Remove This Clock") { [weak self] in self?.removeClock(id) }
        // The last clock can't be removed; Quit is the way to close it.
        remove.isEnabled = store.clocks.count > 1
        menu.addItem(remove)
        menu.autoenablesItems = false
        menu.addItem(.separator())
        menu.addItem(actionMenuItem("Quit Nixie Clock") { NSApp.terminate(nil) })
        return menu
    }
}

/// Makes a menu item that runs a closure, so menus don't need an Objective-C target.
private func actionMenuItem(_ title: String, handler: @escaping () -> Void) -> NSMenuItem {
    let action = MenuAction(handler)
    let item = NSMenuItem(title: title, action: #selector(MenuAction.run), keyEquivalent: "")
    item.target = action
    // A menu item doesn't retain its target; this keeps the action alive with the item.
    item.representedObject = action
    return item
}

private final class MenuAction: NSObject {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func run() {
        handler()
    }
}

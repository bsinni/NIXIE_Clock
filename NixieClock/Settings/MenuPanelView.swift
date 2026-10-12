import SwiftUI

/// The menu bar panel: the list of clocks, settings for the selected one, and Quit.
/// The settings window shows the same view.
struct MenuPanelView: View {
    let manager: ClockManager
    @State private var selectedID: UUID?

    init(manager: ClockManager, selectedID: UUID? = nil) {
        self.manager = manager
        _selectedID = State(initialValue: selectedID)
    }

    private var store: ClockStore { manager.store }

    private var selected: ClockConfig? {
        selectedID.flatMap(store.clock) ?? store.clocks.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nixie Clock").font(.headline)
                Spacer()
                Button {
                    selectedID = manager.addClock()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add a clock")
                .accessibilityLabel("Add clock")
            }

            SectionHeader("Clocks")
            VStack(spacing: 2) {
                ForEach(store.clocks) { clock in
                    ClockRow(clock: clock, isSelected: clock.id == selected?.id) {
                        selectedID = clock.id
                    }
                }
            }

            Divider()

            if let config = selected {
                ClockSettingsView(manager: manager, config: config)
                    // Fresh search field and state for each clock.
                    .id(config.id)
            }

            Divider()

            LaunchAtLoginToggle()

            Divider()

            HStack {
                Button("Remove Clock", role: .destructive) {
                    guard let id = selected?.id else { return }
                    manager.removeClock(id)
                    selectedID = store.clocks.first?.id
                }
                .disabled(store.clocks.count < 2)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 320)
    }
}

// MARK: - Clock list

private struct ClockRow: View {
    let clock: ClockConfig
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 8) {
                Circle()
                    .fill(clock.glowColor)
                    .shadow(color: clock.glowColor, radius: 3)
                    .frame(width: 9, height: 9)
                Text(clock.cityName)
                if clock.locked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Locked")
                }
                Spacer()
                Text(TimeZoneCatalog.offsetText(for: clock.timeZoneID))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.22) : .clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Settings for one clock

private struct ClockSettingsView: View {
    let manager: ClockManager
    let config: ClockConfig
    @State private var query = ""

    private static let backgroundPresets: [(name: String, hex: String)] = [
        ("Black", "#0C0B0B"), ("Midnight Blue", "#141B2B"), ("Dark Mahogany", "#1E1410"),
        ("Charcoal", "#2A2A2C"), ("Parchment", "#E9E4DA")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            timeZoneSection
            glowSection
            backgroundSection
            displaySection
            baseSection
            SettingToggle("Lock position (clicks pass through)", isOn: binding(\.locked))
        }
    }

    // MARK: Time zone

    private var timeZoneSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Time Zone")
            HStack {
                Text(config.cityName)
                Spacer()
                Text(TimeZoneCatalog.offsetText(for: config.timeZoneID))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            TextField("Search cities or zones", text: $query)
                .textFieldStyle(.roundedBorder)

            if !query.isEmpty {
                let results = TimeZoneCatalog.search(query)
                if results.isEmpty {
                    Text("No matching time zones")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(results) { option in
                                Button {
                                    manager.update(config.id) { $0.timeZoneID = option.identifier }
                                    query = ""
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(option.city)
                                            Text(option.detail)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(option.offsetText)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }
                                    .padding(.horizontal, 6)
                                    .frame(height: 34)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: min(CGFloat(results.count), 5) * 34)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
                }
            }
        }
    }

    // MARK: Glow color

    private var glowSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Glow Color")
            HStack(spacing: 6) {
                ForEach(NixieColor.allCases) { preset in
                    SwatchButton(
                        color: preset.color,
                        name: preset.name,
                        isSelected: config.colorHex.uppercased() == preset.hex,
                        round: true
                    ) {
                        manager.update(config.id) { $0.colorHex = preset.hex }
                    }
                }
                Spacer(minLength: 4)
                Button("Custom…") {
                    let id = config.id
                    manager.colorPanel.show(initial: NSColor(config.glowColor), showsAlpha: false) { color in
                        manager.update(id) { $0.colorHex = color.hexString }
                    }
                }
            }
        }
    }

    // MARK: Background

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Background")
            HStack(spacing: 6) {
                ForEach(Self.backgroundPresets, id: \.hex) { preset in
                    SwatchButton(
                        color: Color(hex: preset.hex) ?? .black,
                        name: preset.name,
                        isSelected: config.backgroundHex.uppercased() == preset.hex
                            && config.backgroundOpacity == 1,
                        round: false
                    ) {
                        manager.update(config.id) {
                            $0.backgroundHex = preset.hex
                            $0.backgroundOpacity = 1
                        }
                    }
                }
                Spacer(minLength: 4)
                Button("Custom…") {
                    let id = config.id
                    manager.colorPanel.show(initial: NSColor(config.backgroundColor), showsAlpha: true) { color in
                        manager.update(id) {
                            $0.backgroundHex = color.hexString
                            $0.backgroundOpacity = Double(color.alphaComponent)
                        }
                    }
                }
            }
            Picker("Background style", selection: binding(\.backgroundStyle)) {
                ForEach(BackgroundStyle.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: Display

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader("Display")
            SettingToggle("24-hour time", isOn: binding(\.use24h))
            SettingToggle("Show seconds", isOn: binding(\.showSeconds))
            SettingToggle("Blink separators", isOn: binding(\.blinkSeparators))
            SettingToggle("Show city plate", isOn: binding(\.showPlate))
            SettingToggle("Animate digit changes", isOn: binding(\.animateDigits))
                .help("Crossfade tubes when a digit changes. Turn off to use a little less CPU.")
            SettingToggle("Hourly digit cycle", isOn: binding(\.cathodeCycle))
                .help("At the top of each hour, every tube runs through all ten digits, as real nixie clocks do.")
        }
    }

    // MARK: Base and size

    private var baseSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Base")
            Picker("Wood finish", selection: binding(\.wood)) {
                ForEach(WoodFinish.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack {
                Text("Size")
                Slider(
                    value: Binding(
                        get: { Double(ClockWindowController.scale(of: config)) },
                        set: { manager.setScale(CGFloat($0), for: config.id) }
                    ),
                    in: 0.5...2.0
                )
                .accessibilityLabel("Size")
                Text("\(Int((ClockWindowController.scale(of: config) * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            Button("Reset Size and Position") {
                manager.resetFrame(for: config.id)
            }
            .controlSize(.small)
        }
    }

    // MARK: Helpers

    private func binding<T>(_ keyPath: WritableKeyPath<ClockConfig, T>) -> Binding<T> {
        let id = config.id
        return Binding(
            get: { config[keyPath: keyPath] },
            set: { value in manager.update(id) { $0[keyPath: keyPath] = value } }
        )
    }
}

// MARK: - App-wide settings

private struct LaunchAtLoginToggle: View {
    @State private var isEnabled = LaunchAtLogin.isEnabled
    @State private var needsApproval = LaunchAtLogin.needsApproval
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SettingToggle("Launch at login", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    do {
                        try LaunchAtLogin.setEnabled(newValue)
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    refresh()
                }
            ))
            if needsApproval {
                HStack(spacing: 4) {
                    Text("Needs approval in Login Items.")
                    Button("Open Settings") { LaunchAtLogin.openLoginItemsSettings() }
                        .buttonStyle(.link)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        isEnabled = LaunchAtLogin.isEnabled
        needsApproval = LaunchAtLogin.needsApproval
    }
}

// MARK: - Small pieces

private struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

/// A switch with its label on the left and the switch aligned to the right edge.
private struct SettingToggle: View {
    let title: String
    @Binding var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}

private struct SwatchButton: View {
    let color: Color
    let name: String
    let isSelected: Bool
    let round: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let shape = RoundedRectangle(cornerRadius: round ? 11 : 5, style: .continuous)
            shape
                .fill(color)
                .frame(width: 22, height: 22)
                .overlay(shape.strokeBorder(.primary.opacity(0.25), lineWidth: 1))
                .padding(2)
                .overlay(shape.inset(by: -1).strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .help(name)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

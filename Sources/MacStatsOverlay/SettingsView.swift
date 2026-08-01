import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section("Modules") {
                ForEach(StatsModule.allCases) { module in
                    Toggle(isOn: preferences.binding(for: module)) {
                        Label(module.title, systemImage: module.symbolName)
                    }
                }
                Toggle(isOn: $preferences.showPerCoreBars) {
                    Label("Per-core CPU bars", systemImage: "chart.bar.fill")
                }
            }

            Section("Behavior") {
                Picker("Refresh interval", selection: $preferences.refreshInterval) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                }
                Toggle(isOn: $launchAtLogin) {
                    Label("Launch at login", systemImage: "power")
                }
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        launchAtLoginError = nil
                    } catch {
                        launchAtLoginError = error.localizedDescription
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Shortcut") {
                LabeledContent("Toggle overlay") {
                    Text("⌥ ⌘ S")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
                LabeledContent("Close overlay") {
                    Text("Esc or click outside")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 520)
    }
}

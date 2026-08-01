import Foundation
import SwiftUI

enum StatsModule: String, CaseIterable, Identifiable {
    case systemInfo = "module.systemInfo"
    case cpu = "module.cpu"
    case memory = "module.memory"
    case storage = "module.storage"
    case network = "module.network"
    case battery = "module.battery"
    case temperature = "module.temperature"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemInfo: "System Info"
        case .cpu: "CPU"
        case .memory: "Memory"
        case .storage: "Storage"
        case .network: "Network"
        case .battery: "Battery"
        case .temperature: "Temperature"
        }
    }

    var symbolName: String {
        switch self {
        case .systemInfo: "desktopcomputer"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .network: "network"
        case .battery: "battery.75percent"
        case .temperature: "thermometer.medium"
        }
    }
}

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("module.systemInfo") var showSystemInfo = true
    @AppStorage("module.cpu") var showCPU = true
    @AppStorage("module.memory") var showMemory = true
    @AppStorage("module.storage") var showStorage = true
    @AppStorage("module.network") var showNetwork = true
    @AppStorage("module.battery") var showBattery = true
    @AppStorage("module.temperature") var showTemperature = true
    @AppStorage("refreshInterval") var refreshInterval = 2.0
    @AppStorage("showPerCoreBars") var showPerCoreBars = true

    func isEnabled(_ module: StatsModule) -> Bool {
        switch module {
        case .systemInfo: showSystemInfo
        case .cpu: showCPU
        case .memory: showMemory
        case .storage: showStorage
        case .network: showNetwork
        case .battery: showBattery
        case .temperature: showTemperature
        }
    }

    func binding(for module: StatsModule) -> Binding<Bool> {
        switch module {
        case .systemInfo: Binding(get: { self.showSystemInfo }, set: { self.showSystemInfo = $0 })
        case .cpu: Binding(get: { self.showCPU }, set: { self.showCPU = $0 })
        case .memory: Binding(get: { self.showMemory }, set: { self.showMemory = $0 })
        case .storage: Binding(get: { self.showStorage }, set: { self.showStorage = $0 })
        case .network: Binding(get: { self.showNetwork }, set: { self.showNetwork = $0 })
        case .battery: Binding(get: { self.showBattery }, set: { self.showBattery = $0 })
        case .temperature: Binding(get: { self.showTemperature }, set: { self.showTemperature = $0 })
        }
    }
}

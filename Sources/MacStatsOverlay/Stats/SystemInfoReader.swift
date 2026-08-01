import Foundation
import IOKit

final class SystemInfoReader {
    private static func sysctlString(_ name: String) -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    /// Marketing name ("MacBook Pro (14-inch, Nov 2024)") from the device tree on
    /// Apple Silicon; falls back to the model identifier elsewhere.
    private static func marketingModelName() -> String {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product")
        guard entry != 0 else { return "" }
        defer { IOObjectRelease(entry) }
        guard let value = IORegistryEntryCreateCFProperty(entry, "product-name" as CFString,
                                                          kCFAllocatorDefault, 0)?.takeRetainedValue(),
              let data = value as? Data
        else { return "" }
        return String(decoding: data.prefix(while: { $0 != 0 }), as: UTF8.self)
    }

    private let modelName: String = {
        let marketing = SystemInfoReader.marketingModelName()
        if !marketing.isEmpty { return marketing }
        let product = SystemInfoReader.sysctlString("hw.product")
        return product.isEmpty ? SystemInfoReader.sysctlString("hw.model") : product
    }()

    private let chip: String = SystemInfoReader.sysctlString("machdep.cpu.brand_string")

    func read() -> SystemInfoSnapshot {
        var snapshot = SystemInfoSnapshot()
        snapshot.hostName = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        snapshot.modelName = modelName
        snapshot.chip = chip

        let version = ProcessInfo.processInfo.operatingSystemVersion
        snapshot.osVersion = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        let uptime = Int(ProcessInfo.processInfo.systemUptime)
        let days = uptime / 86400
        let hours = (uptime % 86400) / 3600
        let minutes = (uptime % 3600) / 60
        snapshot.uptime = days > 0 ? "\(days)d \(hours)h \(minutes)m" : "\(hours)h \(minutes)m"
        return snapshot
    }
}

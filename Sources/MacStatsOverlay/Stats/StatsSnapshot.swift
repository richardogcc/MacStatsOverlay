import Foundation

struct CPUSnapshot {
    var usagePercent: Double = 0          // 0...100, all cores combined
    var perCore: [Double] = []            // 0...100 per core
    var loadAverage: (Double, Double, Double) = (0, 0, 0)
}

struct MemorySnapshot {
    var totalBytes: UInt64 = 0
    var usedBytes: UInt64 = 0
    var appBytes: UInt64 = 0
    var wiredBytes: UInt64 = 0
    var compressedBytes: UInt64 = 0
    var pressurePercent: Double = 0

    var usedPercent: Double {
        totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) * 100
    }
}

struct DiskSnapshot {
    var name: String = "Macintosh HD"
    var totalBytes: Int64 = 0
    var freeBytes: Int64 = 0

    var usedBytes: Int64 { max(0, totalBytes - freeBytes) }
    var usedPercent: Double {
        totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) * 100
    }
}

struct NetworkSnapshot {
    var downloadBytesPerSec: Double = 0
    var uploadBytesPerSec: Double = 0
    var totalReceived: UInt64 = 0
    var totalSent: UInt64 = 0
    var interfaceName: String = ""
    var localIP: String = ""
}

struct BatterySnapshot {
    var present: Bool = false
    var levelPercent: Int = 0
    var isCharging: Bool = false
    var isPluggedIn: Bool = false
    var timeRemainingMinutes: Int = -1    // -1 = unknown/calculating
    var health: String = ""
    var cycleCount: Int = -1
}

struct TemperatureSnapshot {
    var available: Bool = false
    var cpuCelsius: Double = 0
    var sensorCount: Int = 0
}

struct SystemInfoSnapshot {
    var hostName: String = ""
    var modelName: String = ""
    var chip: String = ""
    var osVersion: String = ""
    var uptime: String = ""
}

struct StatsSnapshot {
    var system = SystemInfoSnapshot()
    var cpu = CPUSnapshot()
    var memory = MemorySnapshot()
    var disk = DiskSnapshot()
    var network = NetworkSnapshot()
    var battery = BatterySnapshot()
    var temperature = TemperatureSnapshot()
}

enum ByteFormatter {
    static func string(_ bytes: UInt64) -> String {
        string(Int64(bytes))
    }

    static func string(_ bytes: Int64) -> String {
        let fmt = Foundation.ByteCountFormatter()
        fmt.countStyle = .binary
        return fmt.string(fromByteCount: bytes)
    }

    static func decimal(_ bytes: Int64) -> String {
        let fmt = Foundation.ByteCountFormatter()
        fmt.countStyle = .file
        return fmt.string(fromByteCount: bytes)
    }

    static func speed(_ bytesPerSec: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var value = bytesPerSec
        var idx = 0
        while value >= 1000 && idx < units.count - 1 {
            value /= 1000
            idx += 1
        }
        return String(format: value >= 100 || idx == 0 ? "%.0f %@" : "%.1f %@", value, units[idx])
    }
}

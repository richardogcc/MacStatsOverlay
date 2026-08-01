import Foundation
import IOKit.ps
import IOKit

final class BatteryReader {
    func read() -> BatterySnapshot {
        var snapshot = BatterySnapshot()

        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any]
        else { return snapshot }

        snapshot.present = (description[kIOPSIsPresentKey] as? Bool) ?? false
        guard snapshot.present else { return snapshot }

        let current = (description[kIOPSCurrentCapacityKey] as? Int) ?? 0
        let max = (description[kIOPSMaxCapacityKey] as? Int) ?? 100
        snapshot.levelPercent = max > 0 ? Int(Double(current) / Double(max) * 100) : 0
        snapshot.isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
        snapshot.isPluggedIn = (description[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        snapshot.health = (description[kIOPSBatteryHealthKey] as? String) ?? ""

        let remaining = snapshot.isCharging
            ? (description[kIOPSTimeToFullChargeKey] as? Int) ?? -1
            : (description[kIOPSTimeToEmptyKey] as? Int) ?? -1
        snapshot.timeRemainingMinutes = remaining

        snapshot.cycleCount = Self.cycleCount()
        return snapshot
    }

    private static func cycleCount() -> Int {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return -1 }
        defer { IOObjectRelease(service) }
        guard let value = IORegistryEntryCreateCFProperty(service, "CycleCount" as CFString,
                                                          kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int
        else { return -1 }
        return value
    }
}

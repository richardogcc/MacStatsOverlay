import Foundation
import IOKit

// Private-but-stable IOKit HID APIs used to read temperature sensors on Apple Silicon,
// where the classic AppleSMC user client is not available.
@_silgen_name("IOHIDEventSystemClientCreate")
private func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> Unmanaged<AnyObject>?

@_silgen_name("IOHIDEventSystemClientSetMatching")
private func IOHIDEventSystemClientSetMatching(_ client: AnyObject?, _ matching: CFDictionary?)

@_silgen_name("IOHIDEventSystemClientCopyServices")
private func IOHIDEventSystemClientCopyServices(_ client: AnyObject?) -> Unmanaged<CFArray>?

@_silgen_name("IOHIDServiceClientCopyProperty")
private func IOHIDServiceClientCopyProperty(_ service: AnyObject?, _ key: CFString?) -> Unmanaged<CFTypeRef>?

@_silgen_name("IOHIDServiceClientCopyEvent")
private func IOHIDServiceClientCopyEvent(_ service: AnyObject?, _ type: Int64,
                                         _ options: Int32, _ timestamp: Int64) -> Unmanaged<AnyObject>?

@_silgen_name("IOHIDEventGetFloatValue")
private func IOHIDEventGetFloatValue(_ event: AnyObject?, _ field: Int32) -> Double

/// Reads temperature sensors through IOHIDEventSystemClient (AppleVendor usage page).
/// This is the mechanism that works on Apple Silicon Macs.
final class HIDTemperatureReader {
    private static let kHIDPageAppleVendor: Int32 = 0xff00
    private static let kHIDUsageTemperatureSensor: Int32 = 5
    private static let kIOHIDEventTypeTemperature: Int64 = 15

    private var client: AnyObject?
    private var services: [(name: String, service: AnyObject)] = []

    init() {
        guard let clientRef = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else { return }
        let client = clientRef.takeRetainedValue()
        self.client = client

        let matching = [
            "PrimaryUsagePage": Self.kHIDPageAppleVendor,
            "PrimaryUsage": Self.kHIDUsageTemperatureSensor,
        ] as CFDictionary
        IOHIDEventSystemClientSetMatching(client, matching)

        guard let servicesRef = IOHIDEventSystemClientCopyServices(client) else { return }
        let array = servicesRef.takeRetainedValue() as [AnyObject]
        for service in array {
            let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString)?
                .takeRetainedValue() as? String ?? ""
            services.append((name, service))
        }
    }

    var isAvailable: Bool { !services.isEmpty }

    func read() -> TemperatureSnapshot {
        var snapshot = TemperatureSnapshot()
        guard !services.isEmpty else { return snapshot }

        var cpuValues: [Double] = []
        var allValues: [Double] = []
        for (name, service) in services {
            guard let eventRef = IOHIDServiceClientCopyEvent(service, Self.kIOHIDEventTypeTemperature, 0, 0)
            else { continue }
            let event = eventRef.takeRetainedValue()
            let field = Int32(Self.kIOHIDEventTypeTemperature << 16)
            let value = IOHIDEventGetFloatValue(event, field)
            guard (5...120).contains(value) else { continue }
            allValues.append(value)
            let lowered = name.lowercased()
            // CPU die / core cluster sensors on Apple Silicon.
            if lowered.contains("tdie") || lowered.contains("pacc") || lowered.contains("eacc")
                || lowered.contains("cpu") || lowered.contains("soc") {
                cpuValues.append(value)
            }
        }

        snapshot.sensorCount = allValues.count
        let pool = cpuValues.isEmpty ? allValues : cpuValues
        guard !pool.isEmpty else { return snapshot }
        snapshot.available = true
        snapshot.cpuCelsius = pool.reduce(0, +) / Double(pool.count)
        return snapshot
    }
}

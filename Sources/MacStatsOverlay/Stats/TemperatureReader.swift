import Foundation

/// Facade that picks the working temperature source for this machine:
/// IOHIDEventSystemClient on Apple Silicon, AppleSMC user client on Intel.
final class TemperatureReader {
    private let hid = HIDTemperatureReader()
    private lazy var smc = SMCTemperatureReader()

    func read() -> TemperatureSnapshot {
        if hid.isAvailable {
            return hid.read()
        }
        return smc.read()
    }
}

import Foundation
import IOKit

/// Reads temperature sensors from the AppleSMC service. Works on Intel (TC*P keys, sp78)
/// and Apple Silicon (Tp*/Tg* keys, flt) by enumerating every key starting with "T" and
/// keeping plausible CPU-range readings.
final class SMCTemperatureReader {
    private struct SMCVersion {
        var major: UInt8 = 0, minor: UInt8 = 0, build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    private struct SMCPLimitData {
        var version: UInt16 = 0, length: UInt16 = 0
        var cpuPLimit: UInt32 = 0, gpuPLimit: UInt32 = 0, memPLimit: UInt32 = 0
    }

    private struct SMCKeyInfo {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    private struct SMCParamStruct {
        var key: UInt32 = 0
        var vers = SMCVersion()
        var pLimitData = SMCPLimitData()
        var keyInfo = SMCKeyInfo()
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    private enum Selector: UInt8 {
        case readKey = 5
        case getKeyFromIndex = 8
        case getKeyInfo = 9
    }

    private var connection: io_connect_t = 0
    private var cachedSensorKeys: [UInt32]?

    init() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }
        var conn: io_connect_t = 0
        if IOServiceOpen(service, mach_task_self_, 0, &conn) == kIOReturnSuccess {
            connection = conn
        }
    }

    deinit {
        if connection != 0 { IOServiceClose(connection) }
    }

    func read() -> TemperatureSnapshot {
        var snapshot = TemperatureSnapshot()
        guard connection != 0 else { return snapshot }

        let keys = sensorKeys()
        guard !keys.isEmpty else { return snapshot }

        var cpuValues: [Double] = []
        var allValues: [Double] = []
        for key in keys {
            guard let value = readValue(key: key), (10...120).contains(value) else { continue }
            allValues.append(value)
            let name = Self.keyName(key)
            // Intel CPU die/proximity keys start with "TC"; Apple Silicon perf/eff cores with "Tp".
            if name.hasPrefix("TC") || name.hasPrefix("Tp") || name.hasPrefix("Te") {
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

    // MARK: - Key enumeration

    private func sensorKeys() -> [UInt32] {
        if let cached = cachedSensorKeys { return cached }

        var keys: [UInt32] = []
        if let countValue = readValue(key: Self.keyCode("#KEY"), rawUInt: true) {
            let total = Int(countValue)
            for index in 0..<total {
                var input = SMCParamStruct()
                input.data8 = Selector.getKeyFromIndex.rawValue
                input.data32 = UInt32(index)
                guard let output = call(input), output.result == 0 else { continue }
                let name = Self.keyName(output.key)
                if name.hasPrefix("T") {
                    keys.append(output.key)
                }
            }
        }
        cachedSensorKeys = keys
        return keys
    }

    // MARK: - Reading values

    private func readValue(key: UInt32, rawUInt: Bool = false) -> Double? {
        var infoInput = SMCParamStruct()
        infoInput.key = key
        infoInput.data8 = Selector.getKeyInfo.rawValue
        guard let info = call(infoInput), info.result == 0 else { return nil }

        var readInput = SMCParamStruct()
        readInput.key = key
        readInput.keyInfo = info.keyInfo
        readInput.data8 = Selector.readKey.rawValue
        guard let output = call(readInput), output.result == 0 else { return nil }

        let size = Int(info.keyInfo.dataSize)
        let type = Self.keyName(info.keyInfo.dataType)
        let bytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(size)) }

        if rawUInt {
            // Big-endian unsigned integer (used for the #KEY count).
            return Double(bytes.reduce(UInt64(0)) { $0 << 8 | UInt64($1) })
        }

        switch type {
        case "flt " where size == 4:
            let value = bytes.withUnsafeBytes { $0.load(as: Float32.self) }
            return Double(value)
        case "sp78" where size == 2:
            let raw = Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
            return Double(raw) / 256.0
        case "ui8 " where size == 1:
            return Double(bytes[0])
        case "ui16" where size == 2:
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
        default:
            return nil
        }
    }

    private func call(_ input: SMCParamStruct) -> SMCParamStruct? {
        var input = input
        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.stride
        let result = IOConnectCallStructMethod(connection, 2, &input,
                                               MemoryLayout<SMCParamStruct>.stride,
                                               &output, &outputSize)
        return result == kIOReturnSuccess ? output : nil
    }

    // MARK: - Key helpers

    private static func keyCode(_ name: String) -> UInt32 {
        name.utf8.reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
    }

    private static func keyName(_ code: UInt32) -> String {
        let scalars = [24, 16, 8, 0].map { Character(UnicodeScalar(UInt8((code >> $0) & 0xFF))) }
        return String(scalars)
    }
}

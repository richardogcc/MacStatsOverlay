import Foundation
import Darwin

final class MemoryReader {
    private let totalBytes: UInt64 = {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }()

    func read() -> MemorySnapshot {
        var snapshot = MemorySnapshot()
        snapshot.totalBytes = totalBytes

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return snapshot }

        var hostPageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &hostPageSize)
        let pageSize = UInt64(hostPageSize)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let speculative = UInt64(stats.speculative_count) * pageSize
        let internalPages = UInt64(stats.internal_page_count) * pageSize
        let purgeable = UInt64(stats.purgeable_count) * pageSize
        let external = UInt64(stats.external_page_count) * pageSize

        // Approximates Activity Monitor: app memory + wired + compressed
        let app = internalPages > purgeable ? internalPages - purgeable : active + speculative - external
        snapshot.appBytes = app
        snapshot.wiredBytes = wired
        snapshot.compressedBytes = compressed
        snapshot.usedBytes = min(app + wired + compressed, totalBytes)
        snapshot.pressurePercent = totalBytes > 0
            ? Double(wired + compressed) / Double(totalBytes) * 100
            : 0
        return snapshot
    }
}

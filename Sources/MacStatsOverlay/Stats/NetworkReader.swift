import Foundation
import Darwin

/// Sums traffic across physical interfaces (en*) and computes per-second rates from deltas.
final class NetworkReader {
    private var previousReceived: UInt64 = 0
    private var previousSent: UInt64 = 0
    private var previousTime: Date?

    func read() -> NetworkSnapshot {
        var snapshot = NetworkSnapshot()

        var addrsPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrsPointer) == 0, let first = addrsPointer else { return snapshot }
        defer { freeifaddrs(addrsPointer) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var primaryInterface = ""
        var localIP = ""

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            let name = String(cString: ifa.pointee.ifa_name)
            let flags = Int32(ifa.pointee.ifa_flags)
            let family = ifa.pointee.ifa_addr?.pointee.sa_family

            if name.hasPrefix("en"), family == UInt8(AF_LINK),
               let data = ifa.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                received &+= UInt64(data.pointee.ifi_ibytes)
                sent &+= UInt64(data.pointee.ifi_obytes)
            }

            if name.hasPrefix("en"), family == UInt8(AF_INET),
               (flags & IFF_UP) != 0, (flags & IFF_RUNNING) != 0, localIP.isEmpty {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ifa.pointee.ifa_addr, socklen_t(ifa.pointee.ifa_addr.pointee.sa_len),
                               &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    localIP = String(cString: host)
                    primaryInterface = name
                }
            }
            cursor = ifa.pointee.ifa_next
        }

        snapshot.totalReceived = received
        snapshot.totalSent = sent
        snapshot.interfaceName = primaryInterface
        snapshot.localIP = localIP

        let now = Date()
        if let previous = previousTime {
            let elapsed = now.timeIntervalSince(previous)
            if elapsed > 0 {
                // ifi_ibytes is 32-bit and wraps; skip the sample when it goes backwards.
                if received >= previousReceived {
                    snapshot.downloadBytesPerSec = Double(received - previousReceived) / elapsed
                }
                if sent >= previousSent {
                    snapshot.uploadBytesPerSec = Double(sent - previousSent) / elapsed
                }
            }
        }
        previousReceived = received
        previousSent = sent
        previousTime = now
        return snapshot
    }
}

import Foundation

final class DiskReader {
    func read() -> DiskSnapshot {
        var snapshot = DiskSnapshot()
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeNameKey,
            ])
            snapshot.totalBytes = Int64(values.volumeTotalCapacity ?? 0)
            snapshot.freeBytes = values.volumeAvailableCapacityForImportantUsage ?? 0
            snapshot.name = values.volumeName ?? "Macintosh HD"
        } catch {
            // Leave zeroed snapshot; the UI shows a dash for empty values.
        }
        return snapshot
    }
}

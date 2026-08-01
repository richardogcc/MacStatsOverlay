import Foundation
import Combine

@MainActor
final class StatsEngine: ObservableObject {
    @Published private(set) var snapshot = StatsSnapshot()

    private let cpu = CPUReader()
    private let memory = MemoryReader()
    private let disk = DiskReader()
    private let network = NetworkReader()
    private let battery = BatteryReader()
    private let temperature = TemperatureReader()
    private let systemInfo = SystemInfoReader()

    private var timer: Timer?

    var isRunning: Bool { timer != nil }

    func start(interval: TimeInterval) {
        stop()
        refresh()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        var next = StatsSnapshot()
        next.system = systemInfo.read()
        next.cpu = cpu.read()
        next.memory = memory.read()
        next.disk = disk.read()
        next.network = network.read()
        next.battery = battery.read()
        next.temperature = temperature.read()
        snapshot = next
    }
}

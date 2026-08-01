import Foundation
import Darwin

/// Reads per-core CPU usage from host_processor_info, computing deltas between calls.
final class CPUReader {
    private var previousTicks: [[UInt32]] = []

    func read() -> CPUSnapshot {
        var snapshot = CPUSnapshot()

        var loads = [Double](repeating: 0, count: 3)
        getloadavg(&loads, 3)
        snapshot.loadAverage = (loads[0], loads[1], loads[2])

        var cpuCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                         &cpuCount, &infoArray, &infoCount)
        guard result == KERN_SUCCESS, let info = infoArray else { return snapshot }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)),
                          vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.size))
        }

        let stateCount = Int(CPU_STATE_MAX)
        var currentTicks: [[UInt32]] = []
        currentTicks.reserveCapacity(Int(cpuCount))
        for core in 0..<Int(cpuCount) {
            var ticks = [UInt32](repeating: 0, count: stateCount)
            for state in 0..<stateCount {
                ticks[state] = UInt32(bitPattern: info[core * stateCount + state])
            }
            currentTicks.append(ticks)
        }

        if previousTicks.count == currentTicks.count {
            var perCore: [Double] = []
            for core in 0..<currentTicks.count {
                let user = Double(currentTicks[core][Int(CPU_STATE_USER)] &- previousTicks[core][Int(CPU_STATE_USER)])
                let system = Double(currentTicks[core][Int(CPU_STATE_SYSTEM)] &- previousTicks[core][Int(CPU_STATE_SYSTEM)])
                let nice = Double(currentTicks[core][Int(CPU_STATE_NICE)] &- previousTicks[core][Int(CPU_STATE_NICE)])
                let idle = Double(currentTicks[core][Int(CPU_STATE_IDLE)] &- previousTicks[core][Int(CPU_STATE_IDLE)])
                let total = user + system + nice + idle
                perCore.append(total > 0 ? (user + system + nice) / total * 100 : 0)
            }
            snapshot.perCore = perCore
            snapshot.usagePercent = perCore.isEmpty ? 0 : perCore.reduce(0, +) / Double(perCore.count)
        }
        previousTicks = currentTicks
        return snapshot
    }
}

import SwiftUI

struct OverlayView: View {
    @ObservedObject var engine: StatsEngine
    @ObservedObject var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if preferences.showSystemInfo { systemInfoCard }
            if preferences.showCPU { cpuCard }
            if preferences.showMemory { memoryCard }
            if preferences.showStorage { storageCard }
            if preferences.showNetwork { networkCard }
            if preferences.showBattery, engine.snapshot.battery.present { batteryCard }
            if preferences.showTemperature { temperatureCard }
        }
        .padding(20)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 28, y: 12)
        .padding(30)
    }

    private var header: some View {
        HStack {
            Image(systemName: "gauge.with.needle.fill")
                .font(.title3)
                .foregroundStyle(.tint)
            Text("Mac Stats")
                .font(.headline)
            Spacer()
            Text(engine.snapshot.system.hostName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Cards

    private var systemInfoCard: some View {
        card(module: .systemInfo) {
            infoRow("Model", engine.snapshot.system.modelName)
            infoRow("Chip", engine.snapshot.system.chip)
            infoRow("macOS", engine.snapshot.system.osVersion)
            infoRow("Uptime", engine.snapshot.system.uptime)
        }
    }

    private var cpuCard: some View {
        let cpu = engine.snapshot.cpu
        return card(module: .cpu, trailing: percentText(cpu.usagePercent)) {
            gaugeBar(value: cpu.usagePercent / 100, tint: tint(for: cpu.usagePercent))
            if preferences.showPerCoreBars, !cpu.perCore.isEmpty {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(cpu.perCore.enumerated()), id: \.offset) { _, usage in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(tint(for: usage).opacity(0.85))
                            .frame(height: max(3, usage / 100 * 26))
                            .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 26, alignment: .bottom)
            }
            infoRow("Load avg", String(format: "%.2f  %.2f  %.2f",
                                       cpu.loadAverage.0, cpu.loadAverage.1, cpu.loadAverage.2))
        }
    }

    private var memoryCard: some View {
        let memory = engine.snapshot.memory
        return card(module: .memory, trailing: percentText(memory.usedPercent)) {
            gaugeBar(value: memory.usedPercent / 100, tint: tint(for: memory.usedPercent))
            infoRow("Used", "\(ByteFormatter.string(memory.usedBytes)) of \(ByteFormatter.string(memory.totalBytes))")
            infoRow("Wired / Compressed",
                    "\(ByteFormatter.string(memory.wiredBytes)) / \(ByteFormatter.string(memory.compressedBytes))")
        }
    }

    private var storageCard: some View {
        let disk = engine.snapshot.disk
        return card(module: .storage, trailing: percentText(disk.usedPercent)) {
            gaugeBar(value: disk.usedPercent / 100, tint: tint(for: disk.usedPercent))
            infoRow(disk.name, "\(ByteFormatter.decimal(disk.freeBytes)) free of \(ByteFormatter.decimal(disk.totalBytes))")
        }
    }

    private var networkCard: some View {
        let network = engine.snapshot.network
        return card(module: .network) {
            HStack(spacing: 16) {
                Label(ByteFormatter.speed(network.downloadBytesPerSec), systemImage: "arrow.down")
                    .foregroundStyle(.cyan)
                Label(ByteFormatter.speed(network.uploadBytesPerSec), systemImage: "arrow.up")
                    .foregroundStyle(.orange)
            }
            .font(.system(.callout, design: .rounded).weight(.medium))
            .monospacedDigit()
            if !network.localIP.isEmpty {
                infoRow("IP (\(network.interfaceName))", network.localIP)
            }
        }
    }

    private var batteryCard: some View {
        let battery = engine.snapshot.battery
        var detail = battery.isCharging ? "Charging" : (battery.isPluggedIn ? "Plugged in" : "On battery")
        if battery.timeRemainingMinutes > 0 {
            detail += String(format: " · %d:%02d left",
                             battery.timeRemainingMinutes / 60, battery.timeRemainingMinutes % 60)
        }
        return card(module: .battery, trailing: Text("\(battery.levelPercent)%")) {
            gaugeBar(value: Double(battery.levelPercent) / 100,
                     tint: battery.levelPercent <= 20 ? .red : .green)
            infoRow(detail, battery.cycleCount >= 0 ? "\(battery.cycleCount) cycles" : "")
        }
    }

    private var temperatureCard: some View {
        let temperature = engine.snapshot.temperature
        return card(module: .temperature,
                    trailing: Text(temperature.available
                                   ? String(format: "%.0f °C", temperature.cpuCelsius)
                                   : "–")) {
            if temperature.available {
                gaugeBar(value: min(temperature.cpuCelsius, 100) / 100,
                         tint: temperature.cpuCelsius > 80 ? .red
                               : temperature.cpuCelsius > 60 ? .orange : .mint)
                infoRow("Average across \(temperature.sensorCount) sensors", "")
            } else {
                infoRow("Sensors unavailable on this Mac", "")
            }
        }
    }

    // MARK: - Building blocks

    private func card(module: StatsModule,
                      trailing: Text? = nil,
                      @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(module.title, systemImage: module.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                trailing?
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .monospacedDigit()
            }
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    private func percentText(_ value: Double) -> Text {
        Text(String(format: "%.0f%%", value))
    }

    private func gaugeBar(value: Double, tint: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12))
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(6, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 6)
        .animation(.easeOut(duration: 0.4), value: value)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption)
    }

    private func tint(for percent: Double) -> Color {
        percent > 85 ? .red : percent > 65 ? .orange : .accentColor
    }
}

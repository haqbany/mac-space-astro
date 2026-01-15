import SwiftUI
import CoreSystemKit

public class DashboardViewModel: ObservableObject {
    @Published public var memoryStats: MemoryStats?
    @Published public var cpuUsage: Double = 0
    @Published public var diskStats: (used: UInt64, available: UInt64, total: UInt64)?
    
    private let monitor = SystemMonitor()
    private var timer: Timer?
    
    public init() {
        refresh()
        startTimer()
    }
    
    public func refresh() {
        memoryStats = monitor.getMemoryStats()
        cpuUsage = monitor.getCPUUsage()
        diskStats = monitor.getDiskStats()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }
}

public struct DashboardView: View {
    @StateObject var viewModel = DashboardViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Instrument Cluster Header
                HStack(spacing: 40) {
                    GT3Gauge(
                        value: viewModel.cpuUsage,
                        label: "CPU",
                        unit: "% Usage",
                        redline: 85
                    )
                    
                    GT3Gauge(
                        value: viewModel.memoryStats?.pressurePercentage ?? 0,
                        label: "Memory",
                        unit: "Pressure",
                        redline: 75
                    )
                    .scaleEffect(1.2) // Central tachometer feel
                    
                    if let disk = viewModel.diskStats {
                        GT3Gauge(
                            value: (Double(disk.used) / Double(disk.total)) * 100,
                            label: "Storage",
                            unit: "% Full",
                            redline: 90
                        )
                    }
                }
                .padding(.top, 40)
                
                // Detailed Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    // Memory Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Memory Stats", systemImage: "memorychip")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let stats = viewModel.memoryStats {
                            VStack(alignment: .leading, spacing: 8) {
                                MemoryRow(label: "Wired", value: stats.wired, color: .red)
                                MemoryRow(label: "Active", value: stats.active, color: .blue)
                                MemoryRow(label: "Compressed", value: stats.compressed, color: .yellow)
                                MemoryRow(label: "Free", value: stats.free, color: .green)
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding()
                    .background(AstroTheme.cardBackground())
                    
                    // Hardware Info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Hardware", systemImage: "cpu.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total RAM")
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(viewModel.memoryStats?.physicalTotal ?? 0), countStyle: .memory))
                            }
                            HStack {
                                Text("Swap Used")
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(viewModel.memoryStats?.swapUsed ?? 0), countStyle: .memory))
                            }
                        }
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(AstroTheme.cardBackground())
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Precise Engineering • Safety First")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .background(AstroTheme.background)
    }
}

struct MemoryRow: View {
    let label: String
    let value: UInt64
    let color: Color
    
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file))
                .foregroundColor(.secondary)
        }
    }
}

struct MemoryBarView: View {
    let stats: MemoryStats
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle().fill(Color.red).frame(width: geo.size.width * CGFloat(Double(stats.wired) / Double(stats.physicalTotal)))
                Rectangle().fill(Color.blue).frame(width: geo.size.width * CGFloat(Double(stats.active) / Double(stats.physicalTotal)))
                Rectangle().fill(Color.yellow).frame(width: geo.size.width * CGFloat(Double(stats.compressed) / Double(stats.physicalTotal)))
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: geo.size.width * CGFloat(Double(stats.free) / Double(stats.physicalTotal)))
            }
        }
        .frame(height: 12)
        .clipShape(Capsule())
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

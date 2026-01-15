import SwiftUI
import AstroUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct AstroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MenuBarContentView()
                .navigationTitle("Mac Space Astro")
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 750)

        MenuBarExtra {
            MenuBarContentView()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
        
        Window("Image Compressor", id: "image-compressor") {
            ImageCompressorView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 450, height: 550)
    }
}

struct MenuBarLabel: View {
    @StateObject private var monitor = MenuBarMonitor()
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu")
                .font(.system(size: 10))
            Text("\(Int(monitor.cpuUsage))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 12)
            
            Image(systemName: "memorychip")
                .font(.system(size: 10))
            Text("\(Int(monitor.memoryPressure))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .padding(.horizontal, 4)
    }
}

@MainActor
class MenuBarMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var memoryPressure: Double = 0
    
    private var timer: Timer?
    
    init() {
        refresh()
        // Use .common mode so updates happen even when menus/scrolls are active
        let t = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    func refresh() {
        // CPU Usage
        var processorInfo: processor_info_array_t?
        var processorMsgCount: mach_msg_type_number_t = 0
        var processorCount: UInt32 = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &processorInfo, &processorMsgCount)
        
        if result == KERN_SUCCESS, let info = processorInfo {
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            var totalNice: UInt32 = 0
            
            for i in 0..<Int(processorCount) {
                let offset = i * Int(CPU_STATE_MAX)
                totalUser += UInt32(info[offset + Int(CPU_STATE_USER)])
                totalSystem += UInt32(info[offset + Int(CPU_STATE_SYSTEM)])
                totalIdle += UInt32(info[offset + Int(CPU_STATE_IDLE)])
                totalNice += UInt32(info[offset + Int(CPU_STATE_NICE)])
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle + totalNice
            let usedTicks = totalUser + totalSystem + totalNice
            
            cpuUsage = totalTicks > 0 ? (Double(usedTicks) / Double(totalTicks)) * 100 : 0
            
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(processorMsgCount))
        }
        
        // Memory Pressure
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let memResult = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if memResult == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let physicalMemory = ProcessInfo.processInfo.physicalMemory
            
            let wired = UInt64(stats.wire_count) * pageSize
            let active = UInt64(stats.active_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            
            let used = wired + active + compressed
            memoryPressure = (Double(used) / Double(physicalMemory)) * 100
        }
    }
}

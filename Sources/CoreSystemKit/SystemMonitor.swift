import Foundation
import MachO

public struct MemoryStats {
    public let physicalTotal: UInt64
    public let wired: UInt64
    public let active: UInt64
    public let compressed: UInt64
    public let free: UInt64
    public let swapUsed: UInt64
    
    public var totalUsed: UInt64 {
        return wired + active + compressed
    }
    
    public var pressurePercentage: Double {
        // Simple heuristic for pressure
        let used = Double(totalUsed)
        let total = Double(physicalTotal)
        return (used / total) * 100
    }
}

public struct CPUStats {
    public let usagePercentage: Double
    public let coreCount: Int
}

public class SystemMonitor {
    public init() {}
    
    public func getMemoryStats() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStats(physicalTotal: 0, wired: 0, active: 0, compressed: 0, free: 0, swapUsed: 0)
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        let wired = UInt64(stats.wire_count) * pageSize
        let active = UInt64(stats.active_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize
        
        // Swap stats
        var xsw = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &xsw, &size, nil, 0)
        let swapUsed = UInt64(xsw.xsu_used)
        
        return MemoryStats(
            physicalTotal: physicalMemory,
            wired: wired,
            active: active,
            compressed: compressed,
            free: free,
            swapUsed: swapUsed
        )
    }
    
    public func getCPUUsage() -> Double {
        var processorInfo: processor_info_array_t?
        var processorMsgCount: mach_msg_type_number_t = 0
        var processorCount: UInt32 = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &processorInfo, &processorMsgCount)
        
        guard result == KERN_SUCCESS, let info = processorInfo else { return 0 }
        
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
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(processorMsgCount))
        
        return totalTicks > 0 ? (Double(usedTicks) / Double(totalTicks)) * 100 : 0
    }
    
    public func getDiskStats() -> (used: UInt64, available: UInt64, total: UInt64) {
        let fileManager = FileManager.default
        let path = "/"
        
        do {
            let values = try fileManager.attributesOfFileSystem(forPath: path)
            let total = values[.systemSize] as? UInt64 ?? 0
            let free = values[.systemFreeSize] as? UInt64 ?? 0
            return (total - free, free, total)
        } catch {
            return (0, 0, 0)
        }
    }
}

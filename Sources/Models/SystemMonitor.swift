import Foundation
import AppKit

struct SystemStats {
    var cpuUsage: Double = 0
    var memoryUsed: String = "--"
    var memoryUsedShort: String = "--"
    var memoryTotal: String = "--"
    var memoryPercent: Double = 0
    var diskUsed: String = "--"
    var diskTotal: String = "--"
    var networkDown: String = "--"
    var networkUp: String = "--"
    var uptime: String = "--"
    var hostname: String = "--"
}

class SystemMonitor {
    private var previousNetworkBytes: (in: UInt64, out: UInt64) = (0, 0)
    private var cpuHistory: [Double] = Array(repeating: 0, count: 60)

    func getStats() -> SystemStats {
        var stats = SystemStats()
        stats.cpuUsage = getCPUUsage()
        let memInfo = getMemoryInfo()
        stats.memoryUsed = memInfo.used
        stats.memoryUsedShort = memInfo.usedShort
        stats.memoryTotal = memInfo.total
        stats.memoryPercent = memInfo.percent
        let diskInfo = getDiskInfo()
        stats.diskUsed = diskInfo.used
        stats.diskTotal = diskInfo.total
        let network = getNetworkSpeed()
        stats.networkDown = network.down
        stats.networkUp = network.up
        stats.uptime = getUptime()
        stats.hostname = Host.current().localizedName ?? "Mac"
        return stats
    }

    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCPUInfo)
        guard err == KERN_SUCCESS, let info = cpuInfo else { return 0 }

        var totalUser: Double = 0
        var totalSystem: Double = 0
        var totalIdle: Double = 0
        var totalNice: Double = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += Double(info[offset + Int(CPU_STATE_USER)])
            totalSystem += Double(info[offset + Int(CPU_STATE_SYSTEM)])
            totalIdle += Double(info[offset + Int(CPU_STATE_IDLE)])
            totalNice += Double(info[offset + Int(CPU_STATE_NICE)])
        }

        let total = totalUser + totalSystem + totalIdle + totalNice
        let usage = total > 0 ? ((totalUser + totalSystem + totalNice) / total) * 100 : 0

        cpuHistory.removeFirst()
        cpuHistory.append(usage)

        return usage
    }

    private func getMemoryInfo() -> (used: String, usedShort: String, total: String, percent: Double) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return ("--", "--", "--", 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        let used = UInt64(stats.active_count + stats.inactive_count + stats.wire_count) * pageSize
        let percent = Double(used) / Double(total) * 100

        return (formatBytes(used) + " used", formatBytesShort(used), formatBytes(total), percent)
    }

    private func getDiskInfo() -> (used: String, total: String) {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            let totalSpace = attrs[.systemSize] as? UInt64 ?? 0
            let freeSpace = attrs[.systemFreeSize] as? UInt64 ?? 0
            let usedSpace = totalSpace - freeSpace
            return (formatBytes(usedSpace), formatBytes(totalSpace))
        } catch {
            return ("--", "--")
        }
    }

    private func getNetworkSpeed() -> (down: String, up: String) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return ("--", "--") }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = firstAddr
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            if name.hasPrefix("en") || name.hasPrefix("bridge") || name.hasPrefix("awdl") {
                if let data = ptr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    totalIn += UInt64(networkData.pointee.ifi_ibytes)
                    totalOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }

        let speedIn = totalIn >= previousNetworkBytes.in ? totalIn - previousNetworkBytes.in : 0
        let speedOut = totalOut >= previousNetworkBytes.out ? totalOut - previousNetworkBytes.out : 0
        previousNetworkBytes = (totalIn, totalOut)

        return (formatSpeed(speedIn), formatSpeed(speedOut))
    }

    private func getUptime() -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = Int(uptime) % 86400 / 3600
        let minutes = Int(uptime) % 3600 / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_048_576
        if mb >= 1 { return String(format: "%.0f MB", mb) }
        let kb = Double(bytes) / 1024
        return String(format: "%.0f KB", kb)
    }

    private func formatBytesShort(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1fG", gb) }
        let mb = Double(bytes) / 1_048_576
        if mb >= 1 { return String(format: "%.0fM", mb) }
        let kb = Double(bytes) / 1024
        return String(format: "%.0fK", kb)
    }

    private func formatSpeed(_ bytesPerSec: UInt64) -> String {
        if bytesPerSec >= 1_073_741_824 {
            return String(format: "%.1fGB/s", Double(bytesPerSec) / 1_073_741_824)
        } else if bytesPerSec >= 1_048_576 {
            return String(format: "%.1fMB/s", Double(bytesPerSec) / 1_048_576)
        } else if bytesPerSec >= 1024 {
            return String(format: "%.0fKB/s", Double(bytesPerSec) / 1024)
        } else {
            return "\(bytesPerSec)B/s"
        }
    }
}

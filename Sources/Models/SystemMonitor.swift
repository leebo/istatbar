import Foundation

struct SystemStats {
    var cpuUsage: Double = 0
    var memoryUsed: String = "--"
    var memoryTotal: String = "--"
    var memoryShort: String = "--"
    var diskUsed: String?
    var diskTotal: String?
    var networkDown: String = "--"
    var networkUp: String = "--"
}

class SystemMonitor {
    private var previousNetworkBytes: (in: UInt64, out: UInt64) = (0, 0)

    func getStats() -> SystemStats {
        var stats = SystemStats()
        stats.cpuUsage = getCPUUsage()
        let (used, total) = getMemoryInfo()
        stats.memoryUsed = formatBytes(used)
        stats.memoryTotal = formatBytes(total)
        stats.memoryShort = formatBytesShort(used)
        let diskInfo = getDiskInfo()
        stats.diskUsed = diskInfo.used
        stats.diskTotal = diskInfo.total
        let network = getNetworkSpeed()
        stats.networkDown = network.down
        stats.networkUp = network.up
        return stats
    }

    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCPUInfo)
        guard err == KERN_SUCCESS, let info = cpuInfo else { return 0 }

        var totalUsage: Double = 0
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(info[offset + Int(CPU_STATE_USER)])
            let system = Double(info[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Double(info[offset + Int(CPU_STATE_IDLE)])
            let nice = Double(info[offset + Int(CPU_STATE_NICE)])
            totalUsage = user + system + nice + idle
        }
        let total = user + system + idle + nice
        return total > 0 ? ((user + system + nice) / total) * 100 : 0
    }

    private func getMemoryInfo() -> (used: UInt64, total: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        let used = UInt64(stats.active_count + stats.inactive_count + stats.wire_count) * pageSize
        return (used, total)
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
            if name.hasPrefix("en") || name.hasPrefix("bridge") {
                if let data = ptr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    totalIn += UInt64(networkData.pointee.ifi_ibytes)
                    totalOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }

        let speedIn = totalIn - previousNetworkBytes.in
        let speedOut = totalOut - previousNetworkBytes.out
        previousNetworkBytes = (totalIn, totalOut)

        return (formatBytes(speedIn), formatBytes(speedOut))
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.0f MB", mb)
    }

    private func formatBytesShort(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1fG", gb)
    }
}

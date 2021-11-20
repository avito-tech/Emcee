import Benchmarking
import Darwin
import Darwin.Mach
import EmceeLogging
import Foundation
import PlistLib
import ProcessController

public final class MetricsBenchmark: Benchmark {
    private let processControllerProvider: ProcessControllerProvider
    private let timestampProvider: TimestampProvider
    
    public init(
        processControllerProvider: ProcessControllerProvider,
        timestampProvider: TimestampProvider
    ) {
        self.processControllerProvider = processControllerProvider
        self.timestampProvider = timestampProvider
    }
    
    public var name: String { "Gather metrics" }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        var avg = [Double](repeating: 0, count: 3)
        getloadavg(&avg, 3)

        let machFactor = Self.machFactor()

        return [
            timestampProvider.timestampSinceReferencePoint(),
            cpuLoad(),
            numberOfRunningProcesses(),
            numberOfOpenedFiles(),
            freeMemory(),
            usedMemory(),
            swapSizeInMb(),
            avg[0],
            avg[1],
            avg[2],
            machFactor[0],
            machFactor[1],
            machFactor[2],
        ].map { "\($0)" }.joined(separator: ";")
    }
    
    private func cpuLoad() -> BenchmarkResult {
        runCommandAndExtractInt(
            "ps -A -o %cpu | LANG=en_US.UTF-8 awk '{s+=$1} END {print s}' | grep -o -E '[0-9]+' | head -1"
        )
    }
    
    private func numberOfRunningProcesses() -> BenchmarkResult {
        runCommandAndExtractInt(
            "ps aux | wc -l"
        )
    }
    
    private func numberOfOpenedFiles() -> BenchmarkResult {
        runCommandAndExtractInt(
            "sysctl -n kern.num_files"
        )
    }
    
    private func swapSizeInMb() -> BenchmarkResult {
        runCommandAndExtractInt(
            "sysctl -n vm.swapusage | perl -pe 's/(?:^.*?used = ([0-9]+)[.,].*M.*)|.*/\\1/'"
        )
    }
    
    private static let machHost = mach_host_self()
    
    private static func vmStatistics64() -> vm_statistics64 {
        let HOST_VM_INFO64_COUNT: mach_msg_type_number_t = UInt32(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        
        var size     = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        
        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(
                machHost,
                HOST_VM_INFO64,
                $0,
                &size
            )
        }
        
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    
    private func freeMemory() -> Int {
        let vmStats = Self.vmStatistics64()
        return Int(vmStats.free_count) * Int(vm_kernel_page_size)
    }
    
    private func usedMemory() -> Int {
        return Int(ProcessInfo.processInfo.physicalMemory) - freeMemory()
    }
    
    private func runCommandAndExtractInt(_ command: String) -> BenchmarkResult {
        do {
            let streams = CapturedOutputStreams()
            try processControllerProvider.bash(
                command,
                outputStreaming: streams.outputStreaming,
                automaticManagement: .sigintThenKillIfSilent(interval: 10)
            )
            return try Int(
                argumentValue: streams.stdoutSting.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } catch {
            return "\(error)"
        }
    }

    private static func machFactor() -> [Double] {
        let result = Self.hostLoadInfo().mach_factor

        return [
            Double(result.0) / Double(LOAD_SCALE),
            Double(result.1) / Double(LOAD_SCALE),
            Double(result.2) / Double(LOAD_SCALE),
        ]
    }

    private static func hostLoadInfo() -> host_load_info {
        let HOST_LOAD_INFO_COUNT          : mach_msg_type_number_t =
                               UInt32(MemoryLayout<host_load_info_data_t>.size / MemoryLayout<integer_t>.size)

        var size     = HOST_LOAD_INFO_COUNT
        let hostInfo = host_load_info_t.allocate(capacity: 1)

        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(machHost, HOST_LOAD_INFO,
                            $0,
                            &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate()

        return data
    }
}

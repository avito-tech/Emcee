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
        
        do {
            return MappedBenchmarkResult(
                results: [
                    "timestamp": PlistEntry.number(timestampProvider.timestampSinceReferencePoint()),
                    "cpuLoad": PlistEntry.number(Double(try cpuLoad())),
                    "numberOfRunningProcesses": PlistEntry.number(Double(try numberOfRunningProcesses())),
                    "numberOfOpenedFiles": PlistEntry.number(Double(try numberOfOpenedFiles())),
                    "freeMemory": PlistEntry.number(Double(freeMemory())),
                    "usedMemory": PlistEntry.number(Double(usedMemory())),
                    "swapSizeInMb": PlistEntry.number(Double(try swapSizeInMb())),
                    "loadAverage1min": PlistEntry.number(avg[0]),
                    "loadAverage5min": PlistEntry.number(avg[1]),
                    "loadAverage15min": PlistEntry.number(avg[2]),
                ]
            )
        } catch {
            return ErrorBenchmarkResult(error: error)
        }
    }
    
    private func cpuLoad() throws -> Int {
        try runCommandAndExtractInt(
            "ps -A -o %cpu | LANG=en_US.UTF-8 awk '{s+=$1} END {print s}' | grep -o -E '[0-9]+' | head -1"
        )
    }
    
    private func numberOfRunningProcesses() throws -> Int {
        try runCommandAndExtractInt(
            "ps aux | wc -l"
        )
    }
    
    private func numberOfOpenedFiles() throws -> Int {
        try runCommandAndExtractInt(
            "sysctl -n kern.num_files"
        )
    }
    
    private func swapSizeInMb() throws -> Int {
        (try? runCommandAndExtractInt(
            "sysctl -n vm.swapusage | perl -pe 's/(?:^.*?used = ([0-9]+)[.,].*M.*)|.*/\\1/'"
        )) ?? 0
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
    
    private func runCommandAndExtractInt(_ command: String) throws -> Int {
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
            return 0
        }
    }
}

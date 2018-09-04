import ArgumentsParser
import Extensions
import Foundation
import Logging
import ProcessController

final class Main {
    func main() -> Int32 {
        if shouldRunInProcess {
            return runInProcess()
        } else {
            return runOutOfProcessAndCleanup()
        }
    }
    
    private static let runInProcessEnvName = "AVITO_RUNNER_RUN_IN_PROCESS"
    private var shouldRunInProcess: Bool {
        return ProcessInfo.processInfo.environment[Main.runInProcessEnvName] == "true"
    }
    
    private var parentProcessTracker: ParentProcessTracker?
    
    private func runInProcess() -> Int32 {
        log("Arguments: \(ProcessInfo.processInfo.arguments)", color: .blue)
        
        var registry = CommandRegistry(usage: "<subcommand> <options>", overview: "Runs specific tasks related to iOS UI testing")
        
        registry.register(command: DumpRuntimeTestsCommand.self)
        registry.register(command: RunTestsCommand.self)
        registry.register(command: DistRunTestsCommand.self)
        registry.register(command: DistWorkCommand.self)
        
        let exitCode: Int32
        do {
            try startTrackingParentProcessAliveness()
            try registry.run()
            exitCode = 0
        } catch let error {
            log("Error: \(error)")
            exitCode = 1
        }
        log("Finished executing with exit code \(exitCode)")
        return exitCode
    }
    
    private func startTrackingParentProcessAliveness() throws {
        parentProcessTracker = try ParentProcessTracker {
            log("Parent process has died")
            OrphanProcessTracker().killAll()
            exit(3)
        }
    }
    
    private static var innerProcess: Process?
    
    private func runOutOfProcessAndCleanup() -> Int32 {
        let process = Process()
        try? process.setStartsNewProcessGroup(false)
        
        signal(SIGINT, { _ in Main.innerProcess?.interrupt() })
        signal(SIGABRT, { _ in Main.innerProcess?.terminate() })
        signal(SIGTERM, { _ in Main.innerProcess?.terminate() })
        
        process.launchPath = ProcessInfo.processInfo.arguments[0]
        process.arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        var environment = ProcessInfo.processInfo.environment
        environment[Main.runInProcessEnvName] = "true"
        environment[ParentProcessTracker.envName] = String(ProcessInfo.processInfo.processIdentifier)
        process.environment = environment
        Main.innerProcess = process
        process.launch()
        process.waitUntilExit()
        OrphanProcessTracker().killAll()
        return process.terminationStatus
    }
}

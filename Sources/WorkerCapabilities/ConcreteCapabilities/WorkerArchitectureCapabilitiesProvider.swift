//
//  File.swift
//
//
//  Created by a.smolianin on 15.07.2022.
//

import Foundation
import WorkerCapabilitiesModels
import ProcessController
import FileSystem
import DateProvider
import EmceeLogging

public final class WorkerArchitectureCapabilitiesProvider: WorkerCapabilitiesProvider {
    private let logger: ContextualLogger
    private let commandExecutor: CommandExecutor
    
    public init(logger: ContextualLogger, commandExecutor: CommandExecutor) {
        self.logger = logger
        self.commandExecutor = commandExecutor
    }
    
    convenience public init(logger: ContextualLogger) {
        self.init(logger: logger, commandExecutor: DefaultComandExecutor())
    }
    
    public func workerCapabilities() -> Set<WorkerCapability> {
        return Set([WorkerCapability(name: WorkerCapabilityName("emcee.arch"), value: "\(getArch())")])
    }
    
    private func getArch() -> Arch {
        var result = "\(Arch.unknown)"
        do {
            result = try commandExecutor.executeCommandWithOutput(env: [String: String](), arguments: ["/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string"])
            logger.info("Command \"sysctl -n machdep.cpu.brand_string\" = \(result)")
        } catch {
            logger.error("Command \"sysctl -n machdep.cpu.brand_string\" could not be completed. Error: \(error.localizedDescription)")
            return .unknown
        }
        switch result {
        case let arch where arch.contains(Arch.m1.rawValue):
            return .m1
        case let arch where arch.contains(Arch.x86.rawValue):
            return .x86
        default:
            return .unknown
        }
    }
    
    enum Arch: String {
        case m1 = "Apple M1"
        case x86 = "Intel"
        case unknown //for m2 .etc
    }
}

public protocol CommandExecutor {
    func executeCommandWithOutput(env: Dictionary<String,String>, arguments: [String]) throws -> String
}

extension CommandExecutor {
    public func executeCommandWithOutput(env: Dictionary<String,String>, arguments: [String]) throws -> String {
        let dateProvider = SystemDateProvider()
        let filePropertiesProvider = FilePropertiesProviderImpl()
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            filePropertiesProvider: filePropertiesProvider,
            
            subprocess: Subprocess(
                arguments: arguments,
                environment: Environment(env)
            )
        )
        
        var stdoutData = Data()
        controller.onStdout { _, data, _ in stdoutData.append(contentsOf: data) }
        
        try controller.startAndListenUntilProcessDies()
        guard let stdOut = String(data: stdoutData, encoding: .utf8) else {
            return ""
        }
        return stdOut
    }
}

class DefaultComandExecutor: CommandExecutor { }




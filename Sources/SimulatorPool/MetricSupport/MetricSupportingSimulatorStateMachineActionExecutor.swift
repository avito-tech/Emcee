import Foundation
import LocalHostDeterminer
import Metrics
import Models
import PathLib
import SimulatorPoolModels

public final class MetricSupportingSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor {
    let delegate: SimulatorStateMachineActionExecutor
    
    public init(delegate: SimulatorStateMachineActionExecutor) {
        self.delegate = delegate
    }
    
    public func performCreateSimulatorAction(
        environment: [String: String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws -> Simulator {
        return try measure(
            action: .create,
            testDestination: testDestination,
            work: {
                try delegate.performCreateSimulatorAction(
                    environment: environment,
                    testDestination: testDestination,
                    timeout: timeout
                )
            }
        )
    }
    
    public func performBootSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        try measure(
            action: .boot,
            testDestination: simulator.testDestination,
            work: {
                try delegate.performBootSimulatorAction(
                    environment: environment,
                    simulator: simulator,
                    timeout: timeout
                )
            }
        )
    }
    
    public func performShutdownSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        try measure(
            action: .shutdown,
            testDestination: simulator.testDestination,
            work: {
                try delegate.performShutdownSimulatorAction(
                    environment: environment,
                    simulator: simulator,
                    timeout: timeout
                )
            }
        )
    }
    
    public func performDeleteSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        try measure(
            action: .delete,
            testDestination: simulator.testDestination,
            work: {
                try delegate.performDeleteSimulatorAction(
                    environment: environment,
                    simulator: simulator,
                    timeout: timeout
                )
            }
        )
    }
    
    private func measure<T>(
        action: SimulatorDurationMetric.Action,
        testDestination: TestDestination,
        work: () throws -> T
    ) throws -> T {
        let result: Either<T, Error>
        let startTime = Date()
        do {
            result = Either.success(try work())
        } catch {
            result = Either.error(error)
        }
        
        MetricRecorder.capture(
            SimulatorDurationMetric(
                action: action,
                host: LocalHostDeterminer.currentHostAddress,
                testDestination: testDestination,
                isSuccessful: result.isSuccess,
                duration: Date().timeIntervalSince(startTime)
            )
        )
        
        return try result.dematerialize()
    }
}

import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import PathLib
import QueueModels
import SimulatorPoolModels
import Types

public final class MetricSupportingSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor {
    let delegate: SimulatorStateMachineActionExecutor
    private let dateProvider: DateProvider
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        delegate: SimulatorStateMachineActionExecutor,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.delegate = delegate
        self.version = version
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
                duration: dateProvider.currentDate().timeIntervalSince(startTime),
                version: version,
                timestamp: dateProvider.currentDate()
            )
        )
        
        return try result.dematerialize()
    }
}

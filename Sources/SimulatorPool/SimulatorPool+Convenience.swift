import DateProvider
import Foundation
import EmceeLogging
import MetricsRecording
import MetricsExtensions
import QueueModels
import SimulatorPoolModels

public final class AllocatedSimulator {
    public let simulator: Simulator
    public let releaseSimulator: () -> ()

    public init(
        simulator: Simulator,
        releaseSimulator: @escaping () -> ()
    ) {
        self.simulator = simulator
        self.releaseSimulator = releaseSimulator
    }
    
    public func withAutoreleasingSimulator<T>(_ work: (Simulator) throws -> T) rethrows -> T {
        defer {
            releaseSimulator()
        }
        return try work(simulator)
    }
}

public extension SimulatorPool {
    func allocateSimulator(
        dateProvider: DateProvider,
        logger: ContextualLogger,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        version: Version,
        globalMetricRecorder: GlobalMetricRecorder,
        hostname: String
    ) throws -> AllocatedSimulator {
        let logger = logger
        
        return try TimeMeasurerImpl(
            dateProvider: dateProvider
        ).measure(
            work: {
                let simulatorController = try self.allocateSimulatorController()
                simulatorController.apply(simulatorOperationTimeouts: simulatorOperationTimeouts)
                
                do {
                    return AllocatedSimulator(
                        simulator: try simulatorController.bootedSimulator(),
                        releaseSimulator: { self.free(simulatorController: simulatorController) }
                    )
                } catch {
                    logger.error("Failed to get booted simulator: \(error)")
                    try simulatorController.deleteSimulator()
                    throw error
                }
            },
            result: { error, duration in
                globalMetricRecorder.capture(
                    SimulatorAllocationDurationMetric(
                        host: hostname,
                        duration: duration,
                        allocatedSuccessfully: error == nil,
                        version: version,
                        timestamp: dateProvider.currentDate()
                    )
                )
            }
        )
    }
}

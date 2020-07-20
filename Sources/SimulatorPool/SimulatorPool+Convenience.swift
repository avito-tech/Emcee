import DateProvider
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import Models
import QueueModels
import RunnerModels
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
}

public extension SimulatorPool {
    func allocateSimulator(
        dateProvider: DateProvider,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        version: Version
    ) throws -> AllocatedSimulator {
        try TimeMeasurer.measure(
            result: { workSuccessful, duration in
                MetricRecorder.capture(
                    SimulatorAllocationDurationMetric(
                        host: LocalHostDeterminer.currentHostAddress,
                        duration: duration,
                        allocatedSuccessfully: workSuccessful,
                        version: version,
                        timestamp: dateProvider.currentDate()
                    )
                )
            }
        ) {
            let simulatorController = try self.allocateSimulatorController()
            simulatorController.apply(simulatorOperationTimeouts: simulatorOperationTimeouts)

            do {
                return AllocatedSimulator(
                    simulator: try simulatorController.bootedSimulator(),
                    releaseSimulator: { self.free(simulatorController: simulatorController) }
                )
            } catch {
                Logger.error("Failed to get booted simulator: \(error)")
                try simulatorController.deleteSimulator()
                throw error
            }
        }
    }
}

import Logging

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

extension SimulatorPool {
    public func allocateSimulator() throws -> AllocatedSimulator {
        let simulatorController = try self.allocateSimulatorController()

        do {
            return AllocatedSimulator(
                simulator: try simulatorController.bootedSimulator(),
                releaseSimulator: { self.freeSimulatorController(simulatorController) }
            )
        } catch {
            Logger.error("Failed to get booted simulator: \(error)")
            try simulatorController.deleteSimulator()
            throw error
        }
    }
}

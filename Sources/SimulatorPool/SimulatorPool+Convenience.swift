import Logging

public typealias OnSimulatorUsageFinished = () -> ()

extension SimulatorPool where T: SimulatorController {
    public func allocateSimulator() throws -> (Simulator, OnSimulatorUsageFinished) {
        let simulatorController = try self.allocateSimulatorController()

        do {
            return (
                try simulatorController.bootedSimulator(),
                { self.freeSimulatorController(simulatorController) }
            )
        } catch {
            Logger.error("Failed to get booted simulator: \(error)")
            try simulatorController.deleteSimulator()
            throw error
        }
    }
}

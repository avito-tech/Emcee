import Foundation
import Models
import ResourceLocationResolver

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }

    public func createSimulatorController(
        simulator: Simulator,
        simulatorControlTool: SimulatorControlTool,
        developerDir: DeveloperDir
    ) throws -> SimulatorController {
        switch simulatorControlTool {
        case .fbsimctl(let fbsimctlLocation):
            return FbsimctlBasedSimulatorController(
                simulator: simulator,
                fbsimctl: resourceLocationResolver.resolvable(withRepresentable: fbsimctlLocation),
                developerDir: developerDir
            )
        }
    }
}

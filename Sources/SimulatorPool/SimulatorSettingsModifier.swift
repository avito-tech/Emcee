import Foundation
import Models
import SimulatorPoolModels

public protocol SimulatorSettingsModifier {
    func apply(
        developerDir: DeveloperDir,
        simulatorSettings: SimulatorSettings,
        toSimulator: Simulator
    ) throws
}

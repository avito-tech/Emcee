import DeveloperDirModels
import Foundation
import SimulatorPoolModels

public protocol SimulatorSettingsModifier {
    func apply(
        developerDir: DeveloperDir,
        simulatorSettings: SimulatorSettings,
        toSimulator: Simulator
    ) throws
}

import AppleTestModels
import Foundation
import SimulatorPoolModels

public struct AppleRunnerConfiguration: RunnerConfiguration {
    public let appleTestConfiguration: AppleTestConfiguration
    public let lostTestProcessingMode: LostTestProcessingMode
    public let persistentMetricsJobId: String?
    public let simulator: Simulator
    
    public init(
        appleTestConfiguration: AppleTestConfiguration,
        lostTestProcessingMode: LostTestProcessingMode,
        persistentMetricsJobId: String?,
        simulator: Simulator
    ) {
        self.appleTestConfiguration = appleTestConfiguration
        self.lostTestProcessingMode = lostTestProcessingMode
        self.persistentMetricsJobId = persistentMetricsJobId
        self.simulator = simulator
    }
}

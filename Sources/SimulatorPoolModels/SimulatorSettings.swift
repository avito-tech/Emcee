import Foundation

public struct SimulatorSettings: Codable, Hashable, CustomStringConvertible {
    public let simulatorLocalizationSettings: SimulatorLocalizationSettings
    public let watchdogSettings: WatchdogSettings

    public init(
        simulatorLocalizationSettings: SimulatorLocalizationSettings,
        watchdogSettings: WatchdogSettings
    ) {
        self.simulatorLocalizationSettings = simulatorLocalizationSettings
        self.watchdogSettings = watchdogSettings
    }
    
    public var description: String {
        return "<\((type(of: self))): simulatorLocalizationSettings: \(simulatorLocalizationSettings), watchdogSettings: \(watchdogSettings)>"
    }
}

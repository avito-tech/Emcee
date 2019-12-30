import Foundation

public struct SimulatorSettings: Codable, Hashable, CustomStringConvertible {
    /// Location of JSON file with localization settings for Simulator.
    /// These settings will be applied after simulator has been created and before it will be booted.
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

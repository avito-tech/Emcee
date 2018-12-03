import Foundation

public struct SimulatorSettings: Codable, Hashable, CustomStringConvertible {
    /// Location of JSON file with localization settings for Simulator.
    /// These settings will be applied after simulator has been created and before it will be booted.
    public let simulatorLocalizationSettings: SimulatorLocalizationLocation?
    
    /** Absolute path to JSON with watchdog settings for Simulator. */
    public let watchdogSettings: WatchdogSettingsLocation?

    public init(
        simulatorLocalizationSettings: SimulatorLocalizationLocation?,
        watchdogSettings: WatchdogSettingsLocation?
        )
    {
        self.simulatorLocalizationSettings = simulatorLocalizationSettings
        self.watchdogSettings = watchdogSettings
    }
    
    public var description: String {
        let localization = String(describing: simulatorLocalizationSettings)
        let watchdog = String(describing: watchdogSettings)
        return "<\((type(of: self))): localization: \(localization), watchdogSettings: \(watchdog)>"
    }
}

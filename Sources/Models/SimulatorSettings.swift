import Foundation

public struct SimulatorSettings {
    /**
     * Absolute path to JSON with localization settings for Simulator.
     * These settings will be applied after simulator has been created and before it will be booted.
     */
    public let simulatorLocalizationSettings: String?
    
    /** Absolute path to JSON with watchdog settings for Simulator. */
    public let watchdogSettings: String?

    public init(simulatorLocalizationSettings: String?, watchdogSettings: String?) {
        self.simulatorLocalizationSettings = simulatorLocalizationSettings
        self.watchdogSettings = watchdogSettings
    }
}

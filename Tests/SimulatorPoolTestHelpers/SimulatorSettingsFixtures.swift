import Foundation
import SimulatorPoolModels

public final class SimulatorSettingsFixtures {
    var simulatorLocalizationSettings: SimulatorLocalizationSettings = SimulatorLocalizationSettingsFixture().simulatorLocalizationSettings()
    var simulatorKeychainSettings: SimulatorKeychainSettings = SimulatorKeychainSettings(rootCerts: [])
    var watchdogSettings: WatchdogSettings = WatchdogSettings(bundleIds: [], timeout: 0)
    
    public init() {}
    
    public func with(simulatorLocalizationSettings: SimulatorLocalizationSettings) -> SimulatorSettingsFixtures {
        self.simulatorLocalizationSettings = simulatorLocalizationSettings
        return self
    }
    
    public func with(watchdogSettings: WatchdogSettings) -> SimulatorSettingsFixtures {
        self.watchdogSettings = watchdogSettings
        return self
    }
    
    public func simulatorSettings() -> SimulatorSettings {
        return SimulatorSettings(
            simulatorLocalizationSettings: simulatorLocalizationSettings,
            simulatorKeychainSettings: simulatorKeychainSettings,
            watchdogSettings: watchdogSettings
        )
    }
}

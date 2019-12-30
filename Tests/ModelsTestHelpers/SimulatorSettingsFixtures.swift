import Foundation
import Models

public final class SimulatorSettingsFixtures {
    var simulatorLocalizationSettings: SimulatorLocalizationSettings = SimulatorLocalizationSettingsFixture().simulatorLocalizationSettings()
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
            watchdogSettings: watchdogSettings
        )
    }
}

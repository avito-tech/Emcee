import Foundation

public struct SimulatorSettings: Codable, Hashable, CustomStringConvertible {
    public let simulatorLocalizationSettings: SimulatorLocalizationSettings
    public let simulatorKeychainSettings: SimulatorKeychainSettings
    public let watchdogSettings: WatchdogSettings

    public init(
        simulatorLocalizationSettings: SimulatorLocalizationSettings,
        simulatorKeychainSettings: SimulatorKeychainSettings,
        watchdogSettings: WatchdogSettings
    ) {
        self.simulatorLocalizationSettings = simulatorLocalizationSettings
        self.simulatorKeychainSettings = simulatorKeychainSettings
        self.watchdogSettings = watchdogSettings
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case simulatorLocalizationSettings
        case simulatorKeychainSettings
        case watchdogSettings
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.simulatorLocalizationSettings = try container.decode(SimulatorLocalizationSettings.self, forKey: .simulatorLocalizationSettings)
        self.simulatorKeychainSettings = try container.decodeIfPresent(SimulatorKeychainSettings.self, forKey: .simulatorKeychainSettings)
            ?? SimulatorKeychainSettings(rootCerts: [])
        self.watchdogSettings = try container.decode(WatchdogSettings.self, forKey: .watchdogSettings)
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return "<\((type(of: self))): simulatorLocalizationSettings: \(simulatorLocalizationSettings), simulatorKeychainSettings: \(simulatorKeychainSettings), watchdogSettings: \(watchdogSettings)>"
    }
}

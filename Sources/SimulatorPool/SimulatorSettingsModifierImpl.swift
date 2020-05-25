import DeveloperDirLocator
import Foundation
import Models
import PlistLib
import ProcessController
import SimulatorPoolModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class SimulatorSettingsModifierImpl: SimulatorSettingsModifier {
    private let developerDirLocator: DeveloperDirLocator
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        developerDirLocator: DeveloperDirLocator,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.developerDirLocator = developerDirLocator
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func apply(
        developerDir: DeveloperDir,
        simulatorSettings: SimulatorSettings,
        toSimulator simulator: Simulator
    ) throws {
        let environment = ["DEVELOPER_DIR": try developerDirLocator.path(developerDir: developerDir).pathString]
        
        let globalPreferencesPlist = Plist(
            rootPlistEntry: .dict([
                "AppleLocale": .string(simulatorSettings.simulatorLocalizationSettings.localeIdentifier),
                "AppleLanguages": .array(simulatorSettings.simulatorLocalizationSettings.languages.map { .string($0) }),
                "AppleKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.keyboards.map { .string($0) }),
                "ApplePasscodeKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.passcodeKeyboards.map { .string($0) }),
                "AppleKeyboardsExpanded": .number(simulatorSettings.simulatorLocalizationSettings.enableKeyboardExpansion ? 1.0 : 0.0),
                "AddingEmojiKeybordHandled": .bool(simulatorSettings.simulatorLocalizationSettings.addingEmojiKeybordHandled),
            ])
        )
        try importDefaults(domain: ".GlobalPreferences.plist", plistToImport: globalPreferencesPlist, environment: environment, simulator: simulator)
        
        let preferencesPlist = Plist(
            rootPlistEntry: .dict([
                "UIKeyboardDidShowInternationalInfoIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowInternationalInfoAlert),
                "DidShowContinuousPathIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowContinuousPathIntroduction),
            ])
        )
        try importDefaults(domain: "com.apple.Preferences", plistToImport: preferencesPlist, environment: environment, simulator: simulator)
        
        let springboardPlist = Plist(
            rootPlistEntry: .dict([
                "FBLaunchWatchdogExceptions": .dict(simulatorSettings.watchdogSettings.bundleIds.reduce(into: [String: PlistEntry](), {
                    $0[$1] = .number(Double(simulatorSettings.watchdogSettings.timeout))
                })),
            ])
        )
        try importDefaults(domain: "com.apple.springboard", plistToImport: springboardPlist, environment: environment, simulator: simulator)
        
        try kill(daemon: "com.apple.cfprefsd.xpc.daemon", environment: environment, simulator: simulator)
        try kill(daemon: "com.apple.SpringBoard", environment: environment, simulator: simulator)
    }
    
    func pathComponentsForStoringImportablePlists(udid: UDID, domain: String) -> [String] {
        ["sim_settings_patches", "udids", udid.value, "domains", domain]
    }
    
    private func importDefaults(
        domain: String,
        plistToImport: Plist,
        environment: [String: String],
        simulator: Simulator
    ) throws {
        let plistPath = try tempFolder.createFile(
            components: pathComponentsForStoringImportablePlists(udid: simulator.udid, domain: domain),
            filename: uniqueIdentifierGenerator.generate() + ".plist",
            contents: try plistToImport.data(format: .xml)
        )
        try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/xcrun", "simctl", "--set", simulator.simulatorSetPath, "spawn", simulator.udid.value, "defaults", "import", domain, plistPath.pathString],
                environment: environment
            )
        ).startAndWaitForSuccessfulTermination()
    }
    
    private func kill(
        daemon: String,
        environment: [String: String],
        simulator: Simulator
    ) throws {
        try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/xcrun", "simctl", "--set", simulator.simulatorSetPath, "spawn", simulator.udid.value, "launchctl", "kill", "SIGKILL", "system/" + daemon],
                environment: environment
            )
        ).startAndWaitForSuccessfulTermination()
    }
}

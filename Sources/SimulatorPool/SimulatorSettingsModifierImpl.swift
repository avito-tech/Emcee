import DeveloperDirLocator
import DeveloperDirModels
import Foundation
import PlistLib
import ProcessController
import SimulatorPoolModels
import Tmp
import UniqueIdentifierGenerator
import ResourceLocationResolver
import PathLib

public final class SimulatorSettingsModifierImpl: SimulatorSettingsModifier {
    private let developerDirLocator: DeveloperDirLocator
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        developerDirLocator: DeveloperDirLocator,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.developerDirLocator = developerDirLocator
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func apply(
        developerDir: DeveloperDir,
        simulatorSettings: SimulatorSettings,
        toSimulator simulator: Simulator
    ) throws {
        let environment = Environment(try developerDirLocator.suitableEnvironment(forDeveloperDir: developerDir))
        var didImportPlist = false
        
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
        didImportPlist = try didImportPlist || importDefaults(
            domain: ".GlobalPreferences.plist",
            plistToImport: globalPreferencesPlist,
            environment: environment,
            simulator: simulator
        )
        
        let preferencesPlist = Plist(
            rootPlistEntry: .dict([
                "UIKeyboardDidShowInternationalInfoIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowInternationalInfoAlert),
                "DidShowContinuousPathIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowContinuousPathIntroduction),
            ])
        )
        didImportPlist = try didImportPlist || importDefaults(
            domain: "com.apple.Preferences",
            plistToImport: preferencesPlist,
            environment: environment,
            simulator: simulator
        )
        
        let springboardPlist = Plist(
            rootPlistEntry: .dict([
                "FBLaunchWatchdogExceptions": .dict(simulatorSettings.watchdogSettings.bundleIds.reduce(into: [String: PlistEntry](), {
                    $0[$1] = .number(Double(simulatorSettings.watchdogSettings.timeout))
                })),
            ])
        )
        didImportPlist = try didImportPlist || importDefaults(
            domain: "com.apple.springboard",
            plistToImport: springboardPlist,
            environment: environment,
            simulator: simulator
        )
        
        try addRootCertsKeychain(
            rootCerts: simulatorSettings.simulatorKeychainSettings.rootCerts,
            environment: environment,
            simulator: simulator
        )
        
        if didImportPlist {
            try kill(daemon: "com.apple.cfprefsd.xpc.daemon", environment: environment, simulator: simulator)
            try kill(daemon: "com.apple.SpringBoard", environment: environment, simulator: simulator)
        }
    }
    
    func pathComponentsForStoringImportablePlists(udid: UDID, domain: String) -> [String] {
        ["sim_settings_patches", "udids", udid.value, "domains", domain]
    }
    
    private func importDefaults(
        domain: String,
        plistToImport: Plist,
        environment: Environment,
        simulator: Simulator
    ) throws -> Bool {
        let uniqueId = uniqueIdentifierGenerator.generate()
        let pathToPlistToImport = try tempFolder.createFile(
            components: pathComponentsForStoringImportablePlists(udid: simulator.udid, domain: domain),
            filename: uniqueId + "_new.plist",
            contents: try plistToImport.data(format: .xml)
        )
        
        let currentPlistFilePath = tempFolder.pathWith(
            components: pathComponentsForStoringImportablePlists(
                udid: simulator.udid,
                domain: domain
            )
        ).appending(component: uniqueId + "_current.plist")
        
        try processControllerProvider.startAndWaitForSuccessfulTermination(
            arguments: ["/usr/bin/xcrun", "simctl", "--set", simulator.simulatorSetPath, "spawn", simulator.udid.value, "defaults", "export", domain, currentPlistFilePath.pathString],
            environment: environment,
            automaticManagement: .sigtermThenKillIfSilent(interval: 30)
        )
        
        let entriesInCurrentPlist: [String: PlistEntry]
        do {
            let currentPlist = try Plist.create(
                fromData: try Data(contentsOf: currentPlistFilePath.fileUrl)
            )
            entriesInCurrentPlist = try currentPlist.root.plistEntry.optionalEntries(
                forKeys: try plistToImport.root.plistEntry.allKeys()
            )
        } catch {
            entriesInCurrentPlist = [:]
        }
        if try plistToImport.root.plistEntry.dictEntry() == entriesInCurrentPlist {
            return false
        }
        
        try processControllerProvider.startAndWaitForSuccessfulTermination(
            arguments: ["/usr/bin/xcrun", "simctl", "--set", simulator.simulatorSetPath, "spawn", simulator.udid.value, "defaults", "import", domain, pathToPlistToImport.pathString],
            environment: environment,
            automaticManagement: .sigtermThenKillIfSilent(interval: 30)
        )
        return true
    }
    
    private func addRootCertsKeychain(
        rootCerts: [SimulatorCertificateLocation],
        environment: Environment,
        simulator: Simulator
    ) throws {
        let certPaths: [AbsolutePath] = try rootCerts.map {
            try resourceLocationResolver
                .resolvePath(resourceLocation: $0.resourceLocation)
                .directlyAccessibleResourcePath()
        }
                
        try certPaths.forEach { certPath in
            try processControllerProvider.startAndWaitForSuccessfulTermination(
                arguments: ["/usr/bin/xcrun", "simctl", "--set", simulator.simulatorSetPath, "keychain", simulator.udid.value, "add-root-cert", certPath],
                environment: environment,
                automaticManagement: .sigtermThenKillIfSilent(interval: 30)
            )
        }
    }
    
    private func kill(
        daemon: String,
        environment: Environment,
        simulator: Simulator
    ) throws {
        try processControllerProvider.startAndWaitForSuccessfulTermination(
            arguments: ["/usr/bin/xcrun", "simctl", "--set", simulator.simulatorSetPath, "spawn", simulator.udid.value, "launchctl", "kill", "SIGKILL", "system/" + daemon],
            environment: environment,
            automaticManagement: .sigtermThenKillIfSilent(interval: 30)
        )
    }
}

extension ProcessControllerProvider {
    func startAndWaitForSuccessfulTermination(
        arguments: [SubprocessArgument],
        environment: Environment,
        automaticManagement: AutomaticManagement = .noManagement
    ) throws {
        try createProcessController(
            subprocess: Subprocess(
                arguments: arguments,
                environment: environment,
                automaticManagement: automaticManagement
            )
        ).startAndWaitForSuccessfulTermination()
    }
}

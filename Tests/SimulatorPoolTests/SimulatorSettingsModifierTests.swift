@testable import SimulatorPool
import DeveloperDirLocatorTestHelpers
import Foundation
import PlistLib
import ProcessController
import ProcessControllerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import Tmp
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class SimulatorSettingsModifierTests: XCTestCase {
    
    lazy var modifier = SimulatorSettingsModifierImpl(
        developerDirLocator: developerDirLocator,
        processControllerProvider: processControllerProvider,
        tempFolder: tempFolder,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    
    func test___patching_global_preferences() throws {
        addChecksForImportingPlist(
            domain: ".GlobalPreferences.plist",
            expectedPlistContentsAfterImportHappens: expectedGlobalPreferencesPlistContents
        )
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___patching_preferences() throws {
        addChecksForImportingPlist(
            domain: "com.apple.Preferences",
            expectedPlistContentsAfterImportHappens: expectedPreferencesPlistContents
        )

        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___patching_stringboard() throws {
        addChecksForImportingPlist(
            domain: "com.apple.springboard",
            expectedPlistContentsAfterImportHappens: expectedSpringboardPlistContents
        )
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___kills_prefs_daemon() throws {
        addChecksForKilling(daemon: "com.apple.cfprefsd.xpc.daemon")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___kills_springboard_daemon() throws {
        addChecksForKilling(daemon: "com.apple.SpringBoard")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___DEVELOPER_DIR_is_present_for_all_subprocess_invocations() throws {
        processControllerProvider.creator = { [developerDirLocator] subprocess -> ProcessController in
            XCTAssertEqual(
                subprocess.environment.values["DEVELOPER_DIR"],
                try developerDirLocator.path(developerDir: .current).pathString,
                "DEVELOPER_DIR env must be used when executing xcrun"
            )
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___when_global_preferences_plist_has_correct_state___it_does_not_get_overwritten() throws {
        addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedGlobalPreferencesPlistContents, domain: ".GlobalPreferences.plist")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___when_preferences_plist_has_correct_state___it_does_not_get_overwritten() throws {
        addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedPreferencesPlistContents, domain: "com.apple.Preferences")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___when_springboard_plist_has_correct_state___it_does_not_get_overwritten() throws {
        addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedSpringboardPlistContents, domain: "com.apple.SpringBoard")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    func test___when_plists_are_all_set___daemons_not_get_killed() throws {
        let checks = [
            checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedGlobalPreferencesPlistContents, domain: ".GlobalPreferences.plist"),
            checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedPreferencesPlistContents, domain: "com.apple.Preferences"),
            checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedSpringboardPlistContents, domain: "com.apple.springboard"),
            checksForNotKilling(daemon: "com.apple.cfprefsd.xpc.daemon"),
            checksForNotKilling(daemon: "com.apple.SpringBoard"),
        ]
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            try checks.forEach { try $0(args) }
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
    }
    
    // MARK: - Helper Methods
    
    private func addChecksForKilling(daemon: String) {
        processControllerProvider.creator = { [simulator, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains("kill"), args.contains("system/" + daemon) {
                XCTAssertEqual(
                    args,
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "launchctl", "kill", "SIGKILL", "system/" + daemon]
                )
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
    }
    
    private func checksForNotKilling(daemon: String, file: StaticString = #file, line: UInt = #line) -> ([String]) -> () {
        return { args in
            if args.contains("kill"), args.contains("system/" + daemon) {
                self.failTest("Daemon \(daemon) has been unexpectedly killed", file: file, line: line)
            }
        }
    }
    
    private func checksWhenPlistIsAlreadyPresentImportDoesNotHappen(
        plist: Plist,
        domain: String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ([String]) throws -> () {
        return { args in
            if args.contains("export"), args.contains(domain) {
                let pathToPlistToWriteTo = self.assertNotNil(file: file, line: line) { args.last }
                try plist.data(format: .xml).write(to: URL(fileURLWithPath: pathToPlistToWriteTo))
            }
            
            if args.contains("import"), args.contains(domain) {
                self.failTest("Unexpected call to import plist for domain \(domain). This should not happen if plist has correct state.", file: file, line: line)
            }
        }
    }
    
    private func addChecksForImportingPlist(
        domain: String,
        expectedPlistContentsAfterImportHappens: Plist,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        processControllerProvider.creator = { subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains("import"), args.contains(domain) {
                XCTAssertEqual(
                    args.dropLast(),
                    ["/usr/bin/xcrun", "simctl", "--set", self.tempFolder.absolutePath.pathString, "spawn", self.simulator.udid.value, "defaults", "import", domain]
                )
                
                let pathToPlistToImport = self.assertNotNil(file: file, line: line) { args.last }
                let plistToImport = try Plist.create(fromData: Data(contentsOf: URL(fileURLWithPath: pathToPlistToImport)))
                
                XCTAssertEqual(plistToImport.root, expectedPlistContentsAfterImportHappens.root)
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
    }
    
    private func addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: Plist, domain: String) {
        let checks = self.checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: plist, domain: domain)
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            try checks(args)
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
    }

    // MARK: - Helper Variables
    
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: self.tempFolder.absolutePath.appending(component: "Dev_Dir"))
    lazy var processControllerProvider = FakeProcessControllerProvider()
    lazy var simulator = Simulator(
        testDestination: TestDestinationFixtures.testDestination,
        udid: UDID(value: "sim_udid"),
        path: tempFolder.absolutePath.appending(component: "sim_path")
    )
    lazy var simulatorSettings = SimulatorSettings(
        simulatorLocalizationSettings: SimulatorLocalizationSettings(
            localeIdentifier: "locale_id",
            keyboards: ["keyboard1", "keyboard2"],
            passcodeKeyboards: ["pass1", "pass2"],
            languages: ["lang1", "lang2"],
            addingEmojiKeybordHandled: true,
            enableKeyboardExpansion: true,
            didShowInternationalInfoAlert: true,
            didShowContinuousPathIntroduction: true
        ),
        watchdogSettings: WatchdogSettings(
            bundleIds: ["bundle.id.1", "bundle.id.2"],
            timeout: 42
        )
    )
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: "random_value")
    lazy var plistFileName = uniqueIdentifierGenerator.value + ".plist"
    lazy var expectedGlobalPreferencesPlistContents = Plist(
        rootPlistEntry: .dict([
            "AppleLocale": .string(simulatorSettings.simulatorLocalizationSettings.localeIdentifier),
            "AppleLanguages": .array(simulatorSettings.simulatorLocalizationSettings.languages.map { .string($0) }),
            "AppleKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.keyboards.map { .string($0) }),
            "ApplePasscodeKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.passcodeKeyboards.map { .string($0) }),
            "AppleKeyboardsExpanded": .number(simulatorSettings.simulatorLocalizationSettings.enableKeyboardExpansion ? 1 : 0),
            "AddingEmojiKeybordHandled": .bool(simulatorSettings.simulatorLocalizationSettings.addingEmojiKeybordHandled)
        ])
    )
    lazy var expectedPreferencesPlistContents = Plist(
        rootPlistEntry: .dict([
            "UIKeyboardDidShowInternationalInfoIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowInternationalInfoAlert),
            "DidShowContinuousPathIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowContinuousPathIntroduction),
        ])
    )
    lazy var expectedSpringboardPlistContents = Plist(
        rootPlistEntry: .dict([
            "FBLaunchWatchdogExceptions": .dict([
                "bundle.id.1": .number(42),
                "bundle.id.2": .number(42),
            ]),
        ])
    )
}

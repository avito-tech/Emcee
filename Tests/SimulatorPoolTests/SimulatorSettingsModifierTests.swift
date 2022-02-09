@testable import SimulatorPool
import DeveloperDirLocatorTestHelpers
import Foundation
import PlistLib
import ProcessController
import ProcessControllerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestHelpers
import Tmp
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest
import ResourceLocationResolverTestHelpers

final class SimulatorSettingsModifierTests: XCTestCase {
    
    lazy var modifier = SimulatorSettingsModifierImpl(
        developerDirLocator: developerDirLocator,
        processControllerProvider: processControllerProvider,
        tempFolder: tempFolder,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator,
        resourceLocationResolver: resourceLocationResolver
    )
    
    func test__add_root_certificates() throws {
        let expectation = addChecksForAddingRootCertificatesIntoKeychain()
                
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___patching_global_preferences() throws {
        let expectation = addChecksForImportingPlist(
            domain: ".GlobalPreferences.plist",
            expectedPlistContentsAfterImportHappens: expectedGlobalPreferencesPlistContents
        )
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___patching_preferences() throws {
        let expectation = addChecksForImportingPlist(
            domain: "com.apple.Preferences",
            expectedPlistContentsAfterImportHappens: expectedPreferencesPlistContents
        )

        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test__patching_keyboard_preferences() throws {
        let expectation = addChecksForImportingPlist(
            domain: "com.apple.keyboard.preferences",
            expectedPlistContentsAfterImportHappens: expectedKeyboardPreferencesPlistContents
        )
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___patching_springBoard() throws {
        let expectation = addChecksForImportingPlist(
            domain: "com.apple.SpringBoard",
            expectedPlistContentsAfterImportHappens: expectedSpringBoardPlistContents
        )
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___kills_prefs_daemon() throws {
        let expectation = addChecksForKilling(daemon: "com.apple.cfprefsd.xpc.daemon")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test___kills_springBoard_daemon() throws {
        let expectation = addChecksForKilling(daemon: "com.apple.SpringBoard")
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 5.0)
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
    
    func test___when_global_preferences_plist_has_correct_state___with_extra_values___it_does_not_get_overwritten() throws {
        addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedGlobalPreferencesPlistContentsWithExtraContents, domain: ".GlobalPreferences.plist")
        
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
    
    func test___when_springBoard_plist_has_correct_state___it_does_not_get_overwritten() throws {
        addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedSpringBoardPlistContents, domain: "com.apple.SpringBoard")
        
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
            checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedSpringBoardPlistContents, domain: "com.apple.SpringBoard"),
            checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: expectedKeyboardPreferencesPlistContents, domain: "com.apple.keyboard.preferences"),
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
    
    private func addChecksForKilling(daemon: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "'kill' call expectation")
        
        processControllerProvider.creator = { [simulator, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains("kill"), args.contains("system/" + daemon) {
                expectation.fulfill()
                
                XCTAssertEqual(
                    args,
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "launchctl", "kill", "SIGKILL", "system/" + daemon]
                )
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        return expectation
    }
    
    private func checksForNotKilling(daemon: String, file: StaticString = #file, line: UInt = #line) -> ([String]) -> () {
        return { args in
            if args.contains("kill"), args.contains("system/" + daemon) {
                failTest("Daemon \(daemon) has been unexpectedly killed", file: file, line: line)
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
                let pathToPlistToWriteTo = assertNotNil(file: file, line: line) { args.last }
                try plist.data(format: .xml).write(to: URL(fileURLWithPath: pathToPlistToWriteTo))
            }
            
            if args.contains("import"), args.contains(domain) {
                failTest("Unexpected call to import plist for domain \(domain). This should not happen if plist has correct state.", file: file, line: line)
            }
        }
    }
    
    private func addChecksForImportingPlist(
        domain: String,
        expectedPlistContentsAfterImportHappens: Plist,
        file: StaticString = #file,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "'import \(domain)' call expectation")
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
                        
            if args.contains("import"), args.contains(domain) {
                expectation.fulfill()
                
                XCTAssertEqual(
                    args.dropLast(),
                    ["/usr/bin/xcrun", "simctl", "--set", self.tempFolder.absolutePath.pathString, "spawn", self.simulator.udid.value, "defaults", "import", domain]
                )
                
                let pathToPlistToImport = assertNotNil(file: file, line: line) { args.last }
                let plistToImport = try Plist.create(fromData: Data(contentsOf: URL(fileURLWithPath: pathToPlistToImport)))
                
                XCTAssertEqual(plistToImport.root, expectedPlistContentsAfterImportHappens.root)
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        return expectation
    }
    
    private func addChecksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: Plist, domain: String) {
        let checks = self.checksWhenPlistIsAlreadyPresentImportDoesNotHappen(plist: plist, domain: domain)
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            try checks(args)
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
    }
    
    private func addChecksForAddingRootCertificatesIntoKeychain(
        file: StaticString = #file,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "'add-root-cert' call expectation")
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains("keychain"), args.contains("add-root-cert") {
                expectation.fulfill()
                
                XCTAssertEqual(
                    args,
                    ["/usr/bin/xcrun", "simctl", "--set", self.tempFolder.absolutePath.pathString, "keychain", self.simulator.udid.value, "add-root-cert", "/path/to/cert.pem"]
                )
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        return expectation
    }

    // MARK: - Helper Variables
    
    lazy var developerDirLocator = FakeDeveloperDirLocator(
        result: self.tempFolder.absolutePath.appending("Dev_Dir")
    )
    lazy var processControllerProvider = FakeProcessControllerProvider()
    lazy var simulator = SimulatorFixture.simulator(
        path: tempFolder.absolutePath.appending("sim_path")
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
            didShowContinuousPathIntroduction: true,
            didShowGestureKeyboardIntroduction: true
        ),
        simulatorKeychainSettings: SimulatorKeychainSettings(
            rootCerts: [
                .init(.remoteUrl(URL(string: "http://example.com/cert.zip#cert.pem")!, nil))
            ]
        ),
        watchdogSettings: WatchdogSettings(
            bundleIds: ["bundle.id.1", "bundle.id.2"],
            timeout: 42
        )
    )
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: "random_value")
    lazy var resourceLocationResolver = FakeResourceLocationResolver(resolvingResult: .directlyAccessibleFile(path: "/path/to/cert.pem"))
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
    lazy var expectedGlobalPreferencesPlistContentsWithExtraContents = Plist(
        rootPlistEntry: .dict([
            "AppleLocale": .string(simulatorSettings.simulatorLocalizationSettings.localeIdentifier),
            "AppleLanguages": .array(simulatorSettings.simulatorLocalizationSettings.languages.map { .string($0) }),
            "AppleKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.keyboards.map { .string($0) }),
            "ApplePasscodeKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.passcodeKeyboards.map { .string($0) }),
            "AppleKeyboardsExpanded": .number(simulatorSettings.simulatorLocalizationSettings.enableKeyboardExpansion ? 1 : 0),
            "AddingEmojiKeybordHandled": .bool(simulatorSettings.simulatorLocalizationSettings.addingEmojiKeybordHandled),
            "SomeExtraValueThatSystemAdds": .string("yes"),
        ])
    )
    lazy var expectedPreferencesPlistContents = Plist(
        rootPlistEntry: .dict([
            "UIKeyboardDidShowInternationalInfoIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowInternationalInfoAlert),
            "DidShowContinuousPathIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowContinuousPathIntroduction),
            "DidShowGestureKeyboardIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowGestureKeyboardIntroduction),
        ])
    )
    lazy var expectedKeyboardPreferencesPlistContents = Plist(
        rootPlistEntry: .dict([
            "DidShowContinuousPathIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowContinuousPathIntroduction)
        ])
    )
    lazy var expectedSpringBoardPlistContents = Plist(
        rootPlistEntry: .dict([
            "FBLaunchWatchdogExceptions": .dict([
                "bundle.id.1": .number(42),
                "bundle.id.2": .number(42),
            ]),
        ])
    )
}

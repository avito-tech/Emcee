@testable import SimulatorPool
import DeveloperDirLocatorTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import PlistLib
import ProcessController
import ProcessControllerTestHelpers
import SimulatorPoolModels
import TemporaryStuff
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
        let expectation = XCTestExpectation(description: "Subprocess validated")
        
        processControllerProvider.creator = { [simulator, simulatorSettings, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains(where: { $0.contains(".GlobalPreferences.plist") }) {
                defer { expectation.fulfill() }
                
                XCTAssertEqual(
                    args.dropLast(),
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "defaults", "import", ".GlobalPreferences.plist"]
                )
                
                guard let pathToPlistToImport = args.last else { self.failTest("No path to plist") }
                let plistToImport = try Plist.create(fromData: Data(contentsOf: URL(fileURLWithPath: pathToPlistToImport)))
                let expectedPlistContents = Plist(
                    rootPlistEntry: .dict([
                        "AppleLocale": .string(simulatorSettings.simulatorLocalizationSettings.localeIdentifier),
                        "AppleLanguages": .array(simulatorSettings.simulatorLocalizationSettings.languages.map { .string($0) }),
                        "AppleKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.keyboards.map { .string($0) }),
                        "ApplePasscodeKeyboards": .array(simulatorSettings.simulatorLocalizationSettings.passcodeKeyboards.map { .string($0) }),
                        "AppleKeyboardsExpanded": .number(simulatorSettings.simulatorLocalizationSettings.enableKeyboardExpansion ? 1 : 0),
                        "AddingEmojiKeybordHandled": .bool(simulatorSettings.simulatorLocalizationSettings.addingEmojiKeybordHandled)
                    ])
                )
                XCTAssertEqual(plistToImport.root, expectedPlistContents.root)
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___patching_preferences() throws {
        let expectation = XCTestExpectation(description: "Subprocess validated")
        
        processControllerProvider.creator = { [simulator, simulatorSettings, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains(where: { $0.contains("com.apple.Preferences") }) {
                defer { expectation.fulfill() }
                
                XCTAssertEqual(
                    args.dropLast(),
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "defaults", "import", "com.apple.Preferences"]
                )
                
                guard let pathToPlistToImport = args.last else { self.failTest("No path to plist") }
                let plistToImport = try Plist.create(fromData: Data(contentsOf: URL(fileURLWithPath: pathToPlistToImport)))
                let expectedPlistContents = Plist(
                    rootPlistEntry: .dict([
                        "UIKeyboardDidShowInternationalInfoIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowInternationalInfoAlert),
                        "DidShowContinuousPathIntroduction": .bool(simulatorSettings.simulatorLocalizationSettings.didShowContinuousPathIntroduction),
                    ])
                )
                XCTAssertEqual(plistToImport.root, expectedPlistContents.root)
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___patching_stringboard() throws {
        let expectation = XCTestExpectation(description: "Subprocess validated")
        
        processControllerProvider.creator = { [simulator, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains(where: { $0.contains("com.apple.springboard") }) {
                defer { expectation.fulfill() }
                
                XCTAssertEqual(
                    args.dropLast(),
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "defaults", "import", "com.apple.springboard"]
                )
                
                guard let pathToPlistToImport = args.last else { self.failTest("No path to plist") }
                let plistToImport = try Plist.create(fromData: Data(contentsOf: URL(fileURLWithPath: pathToPlistToImport)))
                let expectedPlistContents = Plist(
                    rootPlistEntry: .dict([
                        "FBLaunchWatchdogExceptions": .dict([
                            "bundle.id.1": .number(42),
                            "bundle.id.2": .number(42),
                        ]),
                    ])
                )
                XCTAssertEqual(plistToImport.root, expectedPlistContents.root)
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___kills_prefs_daemon() throws {
        let expectation = XCTestExpectation(description: "Subprocess validated")
        
        processControllerProvider.creator = { [simulator, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains(where: { $0.contains("system/com.apple.cfprefsd.xpc.daemon") }) {
                defer { expectation.fulfill() }
                
                XCTAssertEqual(
                    args,
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "launchctl", "kill", "SIGKILL", "system/com.apple.cfprefsd.xpc.daemon"]
                )
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___kills_springboard_daemon() throws {
        let expectation = XCTestExpectation(description: "Subprocess validated")
        
        processControllerProvider.creator = { [simulator, tempFolder] subprocess -> ProcessController in
            let args = try subprocess.arguments.map { try $0.stringValue() }
            
            if args.contains(where: { $0.contains("system/com.apple.SpringBoard") }) {
                defer { expectation.fulfill() }
                
                XCTAssertEqual(
                    args,
                    ["/usr/bin/xcrun", "simctl", "--set", tempFolder.absolutePath.pathString, "spawn", simulator.udid.value, "launchctl", "kill", "SIGKILL", "system/com.apple.SpringBoard"]
                )
            }
            
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___DEVELOPER_DIR_is_present_for_all_subprocess_invocations() throws {
        let expectation = XCTestExpectation(description: "Subprocess validated")
        
        processControllerProvider.creator = { [developerDirLocator] subprocess -> ProcessController in
            defer { expectation.fulfill() }
            
            XCTAssertEqual(
                subprocess.environment["DEVELOPER_DIR"],
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
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___order_of_executions() throws {
        var executedCommands = [String]()
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            executedCommands.append(try subprocess.arguments.map { try $0.stringValue() }.joined(separator: " "))
            return FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
        }
        
        try modifier.apply(
            developerDir: .current,
            simulatorSettings: simulatorSettings,
            toSimulator: simulator
        )
        
        let simulatorSetPath = tempFolder.absolutePath.pathString
        
        XCTAssertEqual(
            executedCommands,
            [
                "/usr/bin/xcrun simctl --set \(simulatorSetPath) spawn sim_udid defaults import .GlobalPreferences.plist " +
                    tempFolder.absolutePath.appending(
                        components: modifier.pathComponentsForStoringImportablePlists(udid: "sim_udid", domain: ".GlobalPreferences.plist") + [plistFileName]
                    ).pathString,
                "/usr/bin/xcrun simctl --set \(simulatorSetPath) spawn sim_udid defaults import com.apple.Preferences " +
                    tempFolder.absolutePath.appending(
                        components: modifier.pathComponentsForStoringImportablePlists(udid: "sim_udid", domain: "com.apple.Preferences") + [plistFileName]
                    ).pathString,
                "/usr/bin/xcrun simctl --set \(simulatorSetPath) spawn sim_udid defaults import com.apple.springboard " +
                    tempFolder.absolutePath.appending(
                        components: modifier.pathComponentsForStoringImportablePlists(udid: "sim_udid", domain: "com.apple.springboard") + [plistFileName]
                    ).pathString,
                "/usr/bin/xcrun simctl --set \(simulatorSetPath) spawn sim_udid launchctl kill SIGKILL system/com.apple.cfprefsd.xpc.daemon",
                "/usr/bin/xcrun simctl --set \(simulatorSetPath) spawn sim_udid launchctl kill SIGKILL system/com.apple.SpringBoard",
            ]
        )
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
}

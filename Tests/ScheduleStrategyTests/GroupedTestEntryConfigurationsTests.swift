@testable import ScheduleStrategy
import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import PluginSupport
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import XCTest

final class GroupedTestEntryConfigurationsTests: XCTestCase {
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    func test___grouping_into_same_group___when_all_fields_match() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test1"))
            .testEntryConfigurations()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test2"))
            .testEntryConfigurations()
        let mixedTestEntryConfigurations = [
            testEntryConfigurations1[0],
            testEntryConfigurations2[0]
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0], testEntryConfigurations1 + testEntryConfigurations2)
    }
    
    func test___grouping_by_TestTimeoutConfiguration() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test1"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test2"))
            .with(testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 1, testRunnerMaximumSilenceDuration: 1))
            .testEntryConfigurations()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test3"))
            .with(testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 2, testRunnerMaximumSilenceDuration: 2))
            .testEntryConfigurations()
        let mixedTestEntryConfigurations = [
            testEntryConfigurations1[0],
            testEntryConfigurations1[1],
            testEntryConfigurations2[0]
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(
            groups,
            [testEntryConfigurations1, testEntryConfigurations2]
        )
    }
    
    func test___grouping_by_SimulatorSettings() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test1"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test2"))
            .with(simulatorSettings: SimulatorSettingsFixtures().simulatorSettings())
            .testEntryConfigurations()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "test3"))
            .with(simulatorSettings: SimulatorSettingsFixtures()
                .with(watchdogSettings: WatchdogSettings(bundleIds: ["a.p.p"], timeout: 123))
                .simulatorSettings())
            .testEntryConfigurations()
        let mixedTestEntryConfigurations = [
            testEntryConfigurations1[0],
            testEntryConfigurations1[1],
            testEntryConfigurations2[0]
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(
            groups,
            [testEntryConfigurations1, testEntryConfigurations2]
        )
    }
    
    func test___grouping_by_TestDestination___preserves_order_and_sorts_by_test_count() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "1", runtime: "11.0"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class3", methodName: "test"))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "2", runtime: "11.0"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .testEntryConfigurations()
            .shuffled()
        let mixedTestEntryConfigurations = [
            testEntryConfigurations1[0],
            testEntryConfigurations2[0],
            testEntryConfigurations2[1],
            testEntryConfigurations1[1],
            testEntryConfigurations1[2]
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0], testEntryConfigurations1)
        XCTAssertEqual(groups[1], testEntryConfigurations2)
    }
    
    func test___grouping_by_BuildArtifacts___preserves_order_and_sorts_by_test_count() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .with(
                buildArtifacts: .iosLogicTests(
                    xcTestBundle: XcTestBundle(
                        location: TestBundleLocation(.localFilePath("/1")),
                        testDiscoveryMode: .parseFunctionSymbols
                    )
                )
            )
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class3", methodName: "test"))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .with(
                buildArtifacts: .iosLogicTests(
                    xcTestBundle: XcTestBundle(
                        location: TestBundleLocation(.localFilePath("/2")),
                        testDiscoveryMode: .parseFunctionSymbols
                    )
                )
            )
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .testEntryConfigurations()
            .shuffled()
        let mixedTestEntryConfigurations = [
            testEntryConfigurations1[0],
            testEntryConfigurations2[0],
            testEntryConfigurations2[1],
            testEntryConfigurations1[1],
            testEntryConfigurations1[2]
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0], testEntryConfigurations1)
        XCTAssertEqual(groups[1], testEntryConfigurations2)
    }
    
    func test___grouping_accounts_TestExecutionBehavior___preserves_order_and_sorts_by_test_count() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class3", methodName: "test"))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 1, testRetryMode: .retryThroughQueue))
            .testEntryConfigurations()
        let mixedTestEntryConfigurations = [
            testEntryConfiguration2[0],
            testEntryConfigurations1[0],
            testEntryConfigurations1[1],
            testEntryConfigurations1[2]
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0], testEntryConfigurations1)
        XCTAssertEqual(groups[1], testEntryConfiguration2)
    }
    
    func test___grouping_accounts_ToolchainConfiguration___preserves_order_and_sorts_by_test_count() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class3", methodName: "test"))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .with(developerDir: .useXcode(CFBundleShortVersionString: "10.2.1"))
            .testEntryConfigurations()
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: testEntryConfiguration2 + testEntryConfigurations1)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0], testEntryConfigurations1)
        XCTAssertEqual(groups[1], testEntryConfiguration2)
    }
    
    func test___grouping_accounts_plugins___preserves_order_and_sorts_by_test_count() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "test"))
            .add(testEntry: TestEntryFixtures.testEntry(className: "class3", methodName: "test"))
            .with(pluginLocations: [PluginLocation(.localFilePath("plugin1"))])
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .with(pluginLocations: [PluginLocation(.localFilePath("plugin2"))])
            .testEntryConfigurations()
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: testEntryConfiguration2 + testEntryConfigurations1)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0], testEntryConfigurations1)
        XCTAssertEqual(groups[1], testEntryConfiguration2)
    }
    
    func test___grouping_merges_tests_by_plugins() {
        let testEntryConfiguration1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test1"))
            .with(pluginLocations: [PluginLocation(.localFilePath("plugin1"))])
            .testEntryConfigurations()
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test2"))
            .with(pluginLocations: [PluginLocation(.localFilePath("plugin2"))])
            .testEntryConfigurations()
        let testEntryConfiguration3 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test3"))
            .with(pluginLocations: [PluginLocation(.localFilePath("plugin1"))])
            .testEntryConfigurations()
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: testEntryConfiguration1 + testEntryConfiguration2 + testEntryConfiguration3)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0], testEntryConfiguration1 + testEntryConfiguration3)
        XCTAssertEqual(groups[1], testEntryConfiguration2)
    }
    
    func test___grouping_mixed_entries___accounts_all_field_values() {
        let testEntryConfiguration1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .with(
                buildArtifacts: .iosLogicTests(
                    xcTestBundle: XcTestBundle(
                        location: TestBundleLocation(.localFilePath("/2")),
                        testDiscoveryMode: .parseFunctionSymbols
                    )
                )
            )
            .testEntryConfigurations()[0]
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 1, testRetryMode: .retryThroughQueue))
            .testEntryConfigurations()[0]
        let testEntryConfiguration3 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "test"))
            .with(testDestination: try! TestDestination(deviceType: "1", runtime: "11.0"))
            .testEntryConfigurations()[0]
        
        let mixedTestEntryConfigurations = [
            testEntryConfiguration1,
            testEntryConfiguration2,
            testEntryConfiguration3
        ]
        
        let grouper = GroupedTestEntryConfigurations(testEntryConfigurations: mixedTestEntryConfigurations)
        let groups = grouper.grouped()
        
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(
            Set<TestEntryConfiguration>(groups.flatMap { $0 }),
            Set<TestEntryConfiguration>(mixedTestEntryConfigurations)
        )
    }

    func test___grouping_same_test_entries_into_different_groups___with_one_class() {
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "1", runtime: "11.0"))
            .add(testEntry: testEntry)
            .add(testEntry: testEntry)
            .add(testEntry: testEntry)
            .testEntryConfigurations()
            .shuffled()

        let groups = GroupedTestEntryConfigurations(
            testEntryConfigurations: testEntryConfigurations
        ).grouped()

        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].count, 1)
        XCTAssertEqual(groups[1].count, 1)
        XCTAssertEqual(groups[2].count, 1)
        XCTAssertEqual(groups[0][0].testEntry, testEntry)
        XCTAssertEqual(groups[1][0].testEntry, testEntry)
        XCTAssertEqual(groups[2][0].testEntry, testEntry)
    }

    func test___grouping_same_test_entries_into_different_groups___with_many_classes() {
        let testEntry1 = TestEntryFixtures.testEntry(className: "class1", methodName: "test")
        let testEntry2 = TestEntryFixtures.testEntry(className: "class2", methodName: "test")
        let testEntry3 = TestEntryFixtures.testEntry(className: "class3", methodName: "test")
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "1", runtime: "11.0"))
            .add(testEntry: testEntry1)
            .add(testEntry: testEntry1)
            .add(testEntry: testEntry1)
            .add(testEntry: testEntry2)
            .add(testEntry: testEntry2)
            .add(testEntry: testEntry2)
            .add(testEntry: testEntry3)
            .add(testEntry: testEntry3)
            .add(testEntry: testEntry3)
            .testEntryConfigurations()
            .shuffled()
        let expectedConfigurations = Set(
            TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "1", runtime: "11.0"))
            .add(testEntry: testEntry1)
            .add(testEntry: testEntry2)
            .add(testEntry: testEntry3)
            .testEntryConfigurations()
            .shuffled()
        )

        let groups = GroupedTestEntryConfigurations(
            testEntryConfigurations: testEntryConfigurations
            ).grouped()

        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].count, 3)
        XCTAssertEqual(groups[1].count, 3)
        XCTAssertEqual(groups[2].count, 3)
        XCTAssertEqual(Set(groups[0]), expectedConfigurations)
        XCTAssertEqual(Set(groups[1]), expectedConfigurations)
        XCTAssertEqual(Set(groups[2]), expectedConfigurations)
    }
}


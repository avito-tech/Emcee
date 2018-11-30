import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class GroupedTestEntryConfigurationsTests: XCTestCase {
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    func test___grouping_by_TestDestination___preserves_order_and_sorts_by_test_count() {
        let testEntryConfigurations1 = TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "1", runtime: "11.0"))
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class2", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class3", methodName: "test", caseId: nil))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .with(testDestination: try! TestDestination(deviceType: "2", runtime: "11.0"))
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class2", methodName: "test", caseId: nil))
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
            .with(buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "1", runner: "1", xcTestBundle: "1", additionalApplicationBundles: ["1"]))
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class2", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class3", methodName: "test", caseId: nil))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfigurations2 = TestEntryConfigurationFixtures()
            .with(buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "2", runner: "2", xcTestBundle: "2", additionalApplicationBundles: ["2"]))
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class2", methodName: "test", caseId: nil))
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
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class2", methodName: "test", caseId: nil))
            .add(testEntry: TestEntry(className: "class3", methodName: "test", caseId: nil))
            .testEntryConfigurations()
            .shuffled()
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .with(testExecutionBehavior: TestExecutionBehavior(numberOfRetries: 1))
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
    
    func test___grouping_mixed_entries___accounts_all_field_values() {
        let testEntryConfiguration1 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .with(buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "1", runner: "1", xcTestBundle: "1", additionalApplicationBundles: ["1"]))
            .testEntryConfigurations()[0]
        let testEntryConfiguration2 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
            .with(testExecutionBehavior: TestExecutionBehavior(numberOfRetries: 1))
            .testEntryConfigurations()[0]
        let testEntryConfiguration3 = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntry(className: "class1", methodName: "test", caseId: nil))
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
}


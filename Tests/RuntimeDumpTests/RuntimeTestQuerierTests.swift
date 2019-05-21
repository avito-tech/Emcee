@testable import RuntimeDump
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import TempFolder
import TestingFakeFbxctest
import XCTest

final class RuntimeTestQuerierTests: XCTestCase {
    let eventBus = EventBus()
    let fbxctest = try! FakeFbxctestExecutableProducer.fakeFbxctestPath(runId: UUID().uuidString)
    let resourceLocationResolver = ResourceLocationResolver()
    let tempFolder = try! TempFolder()
    let simulatorPool = try! OnDemandSimulatorPoolWithDefaultSimulatorControllerMock()
    
    func test__getting_available_tests__withoutAppTestData() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier(testsToRun: [], useAppTestDumpData: false)
        let queryResult = try querier.queryRuntime()
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
        XCTAssertFalse(simulatorPool.poolMethodCalled)
    }
    
    func test__getting_available_tests_while_some_tests_are_missing__withoutAppTestData() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier(
            testsToRun: [TestToRun.testName("nonexistingtest")],
            useAppTestDumpData: false
        )
        let queryResult = try querier.queryRuntime()
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName("nonexistingtest")])
        XCTAssertFalse(simulatorPool.poolMethodCalled)
    }
    
    func test__when_JSON_file_is_missing_throws__withoutAppTestData() throws {
        let querier = runtimeTestQuerier(
            testsToRun: [TestToRun.testName("nonexistingtest")],
            useAppTestDumpData: false
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime())
        XCTAssertFalse(simulatorPool.poolMethodCalled)
    }
    
    func test__when_JSON_file_has_incorrect_format_throws__withoutAppTestData() throws {
        try tempFolder.createFile(
            filename: RuntimeTestQuerier.runtimeTestsJsonFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier(
            testsToRun: [TestToRun.testName("nonexistingtest")],
            useAppTestDumpData: false
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime())
        XCTAssertFalse(simulatorPool.poolMethodCalled)
    }

    func test__getting_available_tests__withAppTestData() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier(testsToRun: [], useAppTestDumpData: true)
        let queryResult = try querier.queryRuntime()
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
        XCTAssertTrue(simulatorPool.poolMethodCalled)
    }

    func test__getting_available_tests_while_some_tests_are_missing__withAppTestData() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier(
            testsToRun: [TestToRun.testName("nonexistingtest")],
            useAppTestDumpData: true
        )
        let queryResult = try querier.queryRuntime()
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName("nonexistingtest")])
        XCTAssertTrue(simulatorPool.poolMethodCalled)
    }

    func test__when_JSON_file_is_missing_throws__withAppTestData() throws {
        let querier = runtimeTestQuerier(
            testsToRun: [TestToRun.testName("nonexistingtest")],
            useAppTestDumpData: true
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime())
        XCTAssertTrue(simulatorPool.poolMethodCalled)
    }

    func test__when_JSON_file_has_incorrect_format_throws__withAppTestData() throws {
        try tempFolder.createFile(
            filename: RuntimeTestQuerier.runtimeTestsJsonFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier(
            testsToRun: [TestToRun.testName("nonexistingtest")],
            useAppTestDumpData: true
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime())
        XCTAssertTrue(simulatorPool.poolMethodCalled)
    }
    
    private func prepareFakeRuntimeDumpOutputForTestQuerier(entries: [RuntimeTestEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try tempFolder.createFile(
            filename: RuntimeTestQuerier.runtimeTestsJsonFilename,
            contents: data)
    }
    
    private func runtimeTestQuerier(testsToRun: [TestToRun], useAppTestDumpData: Bool) -> RuntimeTestQuerier {
        return RuntimeTestQuerier(
            eventBus: eventBus,
            configuration: runtimeDumpConfiguration(testsToRun: testsToRun, useAppTestDumpData: useAppTestDumpData),
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: simulatorPool,
            tempFolder: tempFolder)
    }
    
    private func runtimeDumpConfiguration(testsToRun: [TestToRun], useAppTestDumpData: Bool) -> RuntimeDumpConfiguration {
        let appTestDumpData = useAppTestDumpData ?
            AppTestDumpData(
                appBundle: AppBundleLocation(.localFilePath("")),
                fbsimctl: FbsimctlLocation(.localFilePath(""))
            ) : nil

        return RuntimeDumpConfiguration(
            fbxctest: FbxctestLocation(ResourceLocation.localFilePath(fbxctest)),
            xcTestBundle: TestBundleLocation(ResourceLocation.localFilePath("")),
            appTestDumpData: appTestDumpData,
            testDestination: TestDestinationFixtures.testDestination,
            testsToRun: testsToRun)
    }
}


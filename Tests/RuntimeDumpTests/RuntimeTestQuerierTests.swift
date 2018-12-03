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
    
    func test__getting_available_tests() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier(testsToRun: [])
        let queryResult = try querier.queryRuntime()
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }
    
    func test__getting_available_tests_while_some_tests_are_missing() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier(testsToRun: [TestToRun.caseId(404)])
        let queryResult = try querier.queryRuntime()
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.caseId(404)])
    }
    
    func test__when_JSON_file_is_missing_throws() throws {
        let querier = runtimeTestQuerier(testsToRun: [TestToRun.caseId(404)])
        XCTAssertThrowsError(_ = try querier.queryRuntime())
    }
    
    func test__when_JSON_file_has_incorrect_format_throws() throws {
        try tempFolder.createFile(
            filename: RuntimeTestQuerier.runtimeTestsJsonFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier(testsToRun: [TestToRun.caseId(404)])
        XCTAssertThrowsError(_ = try querier.queryRuntime())
    }
    
    private func prepareFakeRuntimeDumpOutputForTestQuerier(entries: [RuntimeTestEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try tempFolder.createFile(
            filename: RuntimeTestQuerier.runtimeTestsJsonFilename,
            contents: data)
    }
    
    private func runtimeTestQuerier(testsToRun: [TestToRun]) -> RuntimeTestQuerier {
        return RuntimeTestQuerier(
            eventBus: eventBus,
            configuration: runtimeDumpConfiguration(testsToRun: testsToRun),
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
    }
    
    private func runtimeDumpConfiguration(testsToRun: [TestToRun]) -> RuntimeDumpConfiguration {
        return RuntimeDumpConfiguration(
            fbxctest: FbxctestLocation(ResourceLocation.localFilePath(fbxctest)),
            xcTestBundle: TestBundleLocation(ResourceLocation.localFilePath("")),
            testDestination: TestDestinationFixtures.testDestination,
            testsToRun: testsToRun)
    }
}


@testable import BucketQueue
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestEntryHistoryTests: XCTestCase {
    private let fixtures = TestEntryHistoryFixtures(
        testEntry: TestEntryFixtures.testEntry()
    )
    
    func test___isFailingOnWorker___is_false___without_history() {
        let testEntryHistory = TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: []
        )
        
        XCTAssertEqual(
            testEntryHistory.isFailingOnWorker(workerId: "notInHistory"),
            false
        )
    }
    
    func test___isFailingOnWorker___is_true___with_history_of_fails() {
        let testEntryHistory = TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: [
                fixtures.testRunHistoryItem(success: false, workerId: "fail"),
                fixtures.testRunHistoryItem(success: true, workerId: "success")
            ]
        )
        
        XCTAssertEqual(
            testEntryHistory.isFailingOnWorker(workerId: "fail"),
            true
        )
    }
    
    func test___isFailingOnWorker___is_true___without_history_of_fails() {
        let testEntryHistory = TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: [
                fixtures.testRunHistoryItem(success: false, workerId: "fail"),
                fixtures.testRunHistoryItem(success: true, workerId: "success")
            ]
        )
        
        XCTAssertEqual(
            testEntryHistory.isFailingOnWorker(workerId: "success"),
            false
        )
        XCTAssertEqual(
            testEntryHistory.isFailingOnWorker(workerId: "notInHistory"),
            false
        )
    }
    
    func test___isFailingOnWorker___is_false___with_successes_and_failures_mixed_in_history() {
        let testEntryHistory = TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: [
                fixtures.testRunHistoryItem(success: false, workerId: "mixed"),
                fixtures.testRunHistoryItem(success: true, workerId: "mixed"),
                fixtures.testRunHistoryItem(success: false, workerId: "mixed")
            ]
        )
        
        XCTAssertEqual(
            testEntryHistory.isFailingOnWorker(workerId: "mixed"),
            false
        )
    }
    
    func test___numberOfAttempts___is_zero___initially() {
        let testEntryHistory = TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: []
        )
        
        XCTAssertEqual(
            testEntryHistory.numberOfAttempts,
            0
        )
    }
    
    func test___numberOfAttempts___is_correct___with_history() {
        let testEntryHistory = TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: [
                fixtures.testRunHistoryItem(success: false, workerId: "mixed"),
                fixtures.testRunHistoryItem(success: true, workerId: "mixed"),
                fixtures.testRunHistoryItem(success: false, workerId: "mixed")
            ]
        )
        
        XCTAssertEqual(
            testEntryHistory.numberOfAttempts,
            3
        )
    }
}


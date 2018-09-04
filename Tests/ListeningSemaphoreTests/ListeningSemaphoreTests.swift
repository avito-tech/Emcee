import Foundation
@testable import ListeningSemaphore
import XCTest

public final class ListeningSemaphoreTests: XCTestCase {
    let queue = OperationQueue()
    
    func testCreatingWithMaximumValues() {
        let values = ResourceAmounts.of(bootingSimulators: 2, runningTests: 10)
        let semaphore = ListeningSemaphore(maximumValues: values)
        
        XCTAssertEqual(semaphore.availableResources, values)
        XCTAssertEqual(semaphore.usedValues, .zero)
        XCTAssertEqual(semaphore.maximumValues, values)
        XCTAssertEqual(semaphore.queueLength, 0)
    }
    
    func testAcquiringResources() throws {
        let values = ResourceAmounts.of(bootingSimulators: 2)
        let semaphore = ListeningSemaphore(maximumValues: values)
        
        let operation = try semaphore.acquire(.of(bootingSimulators: 1))
        XCTAssertTrue(operation.isReady)
        XCTAssertEqual(semaphore.queueLength, 0)
        XCTAssertEqual(semaphore.availableResources, .of(bootingSimulators: 1))
    }
    
    func testReleasingResources() throws {
        let values = ResourceAmounts.of(bootingSimulators: 2)
        let semaphore = ListeningSemaphore(maximumValues: values)
        
        _ = try semaphore.acquire(.of(bootingSimulators: 1))
        try semaphore.release(.of(bootingSimulators: 1))
        XCTAssertEqual(semaphore.availableResources, values)
    }
    
    func testAcquiringAvailableResourceReleasesOperationImmediately() throws {
        let values = ResourceAmounts.of(bootingSimulators: 2)
        let semaphore = ListeningSemaphore(maximumValues: values)
        let operation = try semaphore.acquire(.of(bootingSimulators: 1))
        
        // we setup a condition that will signal once myOperation will be performed
        let condition = NSCondition()
        let myOperation = BlockOperation { condition.signal() }
        myOperation.addDependency(operation)
        // add operation asynchronously so we have some time to setup a condition check
        queue.addOperation { self.queue.addOperation(myOperation) }
        checkConditionDidSignal(condition)
    }
    
    func testCappingToMaximumAmounts() throws {
        let values = ResourceAmounts.of(bootingSimulators: 2)
        let semaphore = ListeningSemaphore(maximumValues: values)

        let first = try semaphore.acquire(.of(bootingSimulators: 100500))
        XCTAssertEqual(semaphore.availableResources, .zero)
        XCTAssertTrue(first.isReady)
        
        try semaphore.release(.of(bootingSimulators: 100500))
        XCTAssertEqual(semaphore.availableResources, semaphore.maximumValues)
    }
    
    func test_IntegrationTest_ProcessingPendingQueue() throws {
        let values = ResourceAmounts.of(runningTests: 7)
        let semaphore = ListeningSemaphore(maximumValues: values)
        
        let firstOperation = try semaphore.acquire(.of(runningTests: 3))
        XCTAssertTrue(firstOperation.isReady)
        XCTAssertEqual(semaphore.availableResources, .of(runningTests: 4))
        
        // here, semaphore has only 4 available slots to acquire, but we require 5
        // we check that operation is on hold and queue size has increased
        let secondOperation = try semaphore.acquire(ResourceAmounts.of(runningTests: 5))
        XCTAssertFalse(secondOperation.isReady)
        XCTAssertEqual(semaphore.queueLength, 1)
        // the amount of available resources shouldn't change
        XCTAssertEqual(semaphore.availableResources, .of(runningTests: 4))

        // we setup a condition that will signal once f2 will be performed
        let condition = NSCondition()
        let operationWhenF2IsUnheld = BlockOperation { condition.signal() }
        operationWhenF2IsUnheld.addDependency(secondOperation)
        queue.addOperation(operationWhenF2IsUnheld)
        try semaphore.release(.of(runningTests: 3))
        checkConditionDidSignal(condition)
        XCTAssertEqual(semaphore.availableResources, .of(runningTests: 2))

        try semaphore.release(.of(runningTests: 5))
        XCTAssertEqual(semaphore.availableResources, semaphore.maximumValues)
    }
    
    func test_IntegrationTest_ProcessingPendingItemsWithCancelledOperationsReleasesPendingItems() throws {
        let values = ResourceAmounts.of(runningTests: 7)
        let semaphore = ListeningSemaphore(maximumValues: values)
        
        // here, we've acquired some resources.
        _ = try semaphore.acquire(.of(runningTests: 5))
        
        // we ask more resources, but this operation will be blocking until after more resources become available
        let toBeCancelled = try semaphore.acquire(.of(runningTests: 5))
        
        // we subscribe to the resource aquisition
        let condition = NSCondition()
        let myOperation = BlockOperation { condition.signal() }
        toBeCancelled.addCascadeCancellableDependency(myOperation)
        queue.addOperation(myOperation)
        
        // now we cancel the resource acquiring operation, that should cancel myOperation as well,
        // and it should never be performed
        toBeCancelled.cancel()
        XCTAssertTrue(myOperation.isCancelled)
        
        // we release resources acquired for first operation above, making toBeCancelled able to run if it weren't
        // cancelled
        try semaphore.release(.of(runningTests: 5))
        // ensure myOperation actually never executed
        checkConditionDidTimeout(condition)
        
        // since second acquire operation has been cancelled, it shouldn't acquire the resources
        XCTAssertEqual(semaphore.availableResources, semaphore.maximumValues)
        
        // and it should be removed from the pending queue
        XCTAssertEqual(semaphore.queueLength, 0)
    }
    
    func test_IntegrationTest_testAcquiringAndReleasingMultipleResources() throws {
        let values = ResourceAmounts.of(bootingSimulators: 7, runningTests: 7)
        let semaphore = ListeningSemaphore(maximumValues: values)

        let simulatorsOnly = try semaphore.acquire(.of(bootingSimulators: 5))
        XCTAssertTrue(simulatorsOnly.isReady)
        let testsOnly = try semaphore.acquire(.of(runningTests: 5))
        XCTAssertTrue(testsOnly.isReady)
        XCTAssertEqual(semaphore.availableResources, .of(bootingSimulators: 2, runningTests: 2))
        
        let combined = try semaphore.acquire(.of(bootingSimulators: 4, runningTests: 4))
        XCTAssertFalse(combined.isReady)
        XCTAssertEqual(semaphore.queueLength, 1)
        XCTAssertEqual(semaphore.availableResources, .of(bootingSimulators: 2, runningTests: 2))
        
        // release resources of simulatorsOnly operation
        try semaphore.release(.of(bootingSimulators: 5))
        XCTAssertEqual(semaphore.availableResources, .of(bootingSimulators: 7, runningTests: 2))
        XCTAssertFalse(combined.isReady)
        
        // release resources of testsOnly operation, making available resources capable of performing combined operation
        try semaphore.release(.of(runningTests: 5))
        XCTAssertTrue(combined.isReady)
        XCTAssertEqual(semaphore.availableResources, .of(bootingSimulators: 3, runningTests: 3))
    }
    
    private func checkConditionDidSignal(_ condition: NSCondition) {
        // when condition signals, it returns true. If it reaches timeout, it returns false.
        XCTAssertTrue(condition.wait(until: Date().addingTimeInterval(1.0)))
    }
    
    private func checkConditionDidTimeout(_ condition: NSCondition) {
        // when condition signals, it returns true. If it reaches timeout, it returns false.
        XCTAssertFalse(condition.wait(until: Date().addingTimeInterval(1.0)))
    }
}

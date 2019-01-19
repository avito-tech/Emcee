import Foundation
@testable import ListeningSemaphore
import XCTest

public final class ListeningSemaphoreTests: XCTestCase {
    let queue = OperationQueue()
    
    func testCreatingWithMaximumValues() {
        let values = ResourceAmountsDouble.of(firstResource: 2, secondResource: 10)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)
        
        XCTAssertEqual(semaphore.availableResources, values)
        XCTAssertEqual(semaphore.usedValues, .zero)
        XCTAssertEqual(semaphore.maximumValues, values)
        XCTAssertEqual(semaphore.queueLength, 0)
    }
    
    func testAcquiringResources() throws {
        let values = ResourceAmountsDouble.of(firstResource: 2)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)
        
        let operation = try semaphore.acquire(.of(firstResource: 1))
        XCTAssertTrue(operation.isReady)
        XCTAssertEqual(semaphore.queueLength, 0)
        XCTAssertEqual(semaphore.availableResources, .of(firstResource: 1))
    }
    
    func testReleasingResources() throws {
        let values = ResourceAmountsDouble.of(firstResource: 2)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)
        
        _ = try semaphore.acquire(.of(firstResource: 1))
        try semaphore.release(.of(firstResource: 1))
        XCTAssertEqual(semaphore.availableResources, values)
    }
    
    func testAcquiringAvailableResourceReleasesOperationImmediately() throws {
        let values = ResourceAmountsDouble.of(firstResource: 2)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)
        let operation = try semaphore.acquire(.of(firstResource: 1))
        
        // we setup an expectation that will be fulfilled once myOperation will be performed
        let operationInvokedExpectation = expectation(description: "operation has been invoked")
        
        let myOperation = BlockOperation { operationInvokedExpectation.fulfill() }
        myOperation.addDependency(operation)
        // add operation asynchronously so we have some time to setup a condition check
        queue.addOperation { self.queue.addOperation(myOperation) }
        
        wait(for: [operationInvokedExpectation], timeout: 5.0)
    }
    
    func testCappingToMaximumAmounts() throws {
        let values = ResourceAmountsDouble.of(firstResource: 2)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)

        let first = try semaphore.acquire(.of(firstResource: 100500))
        XCTAssertEqual(semaphore.availableResources, .zero)
        XCTAssertTrue(first.isReady)
        
        try semaphore.release(.of(firstResource: 100500))
        XCTAssertEqual(semaphore.availableResources, semaphore.maximumValues)
    }
    
    func test_IntegrationTest_ProcessingPendingQueue() throws {
        let values = ResourceAmountsDouble.of(secondResource: 7)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)
        
        let firstOperation = try semaphore.acquire(.of(secondResource: 3))
        XCTAssertTrue(firstOperation.isReady)
        XCTAssertEqual(semaphore.availableResources, .of(secondResource: 4))
        
        // here, semaphore has only 4 available slots to acquire, but we require 5
        // we check that operation is on hold and queue size has increased
        let secondOperation = try semaphore.acquire(ResourceAmountsDouble.of(secondResource: 5))
        XCTAssertFalse(secondOperation.isReady)
        XCTAssertEqual(semaphore.queueLength, 1)
        // the amount of available resources shouldn't change
        XCTAssertEqual(semaphore.availableResources, .of(secondResource: 4))

        // we setup a condition that will signal once f2 will be performed
        let operationInvokedExpectation = expectation(description: "operation has been invoked")
        let operationWhenF2IsUnheld = BlockOperation { operationInvokedExpectation.fulfill() }
        operationWhenF2IsUnheld.addDependency(secondOperation)
        queue.addOperation(operationWhenF2IsUnheld)
        try semaphore.release(.of(secondResource: 3))
        
        wait(for: [operationInvokedExpectation], timeout: 5.0)
        
        XCTAssertEqual(semaphore.availableResources, .of(secondResource: 2))

        try semaphore.release(.of(secondResource: 5))
        XCTAssertEqual(semaphore.availableResources, semaphore.maximumValues)
    }
    
    func test_IntegrationTest_ProcessingPendingItemsWithCancelledOperationsReleasesPendingItems() throws {
        let values = ResourceAmountsDouble.of(secondResource: 7)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)
        
        // here, we've acquired some resources.
        _ = try semaphore.acquire(.of(secondResource: 5))
        
        // we ask more resources, but this operation will be blocking until after more resources become available
        let toBeCancelled = try semaphore.acquire(.of(secondResource: 5))
        
        // we subscribe to the resource aquisition
        let operationInvokedExpectation = expectation(description: "operation has been invoked")
        operationInvokedExpectation.isInverted = true
        
        let myOperation = BlockOperation { operationInvokedExpectation.fulfill() }
        toBeCancelled.addCascadeCancellableDependency(myOperation)
        queue.addOperation(myOperation)
        
        // now we cancel the resource acquiring operation, that should cancel myOperation as well,
        // and it should never be performed
        toBeCancelled.cancel()
        XCTAssertTrue(myOperation.isCancelled)
        
        // we release resources acquired for first operation above, making toBeCancelled able to run if it weren't
        // cancelled
        try semaphore.release(.of(secondResource: 5))
        // ensure myOperation has never executed
        
        wait(for: [operationInvokedExpectation], timeout: 5.0)
        
        // since second acquire operation has been cancelled, it shouldn't acquire the resources
        XCTAssertEqual(semaphore.availableResources, semaphore.maximumValues)
        
        // and it should be removed from the pending queue
        XCTAssertEqual(semaphore.queueLength, 0)
    }
    
    func test_IntegrationTest_testAcquiringAndReleasingMultipleResources() throws {
        let values = ResourceAmountsDouble.of(firstResource: 7, secondResource: 7)
        let semaphore = ListeningSemaphore<ResourceAmountsDouble>(maximumValues: values)

        let simulatorsOnly = try semaphore.acquire(.of(firstResource: 5))
        XCTAssertTrue(simulatorsOnly.isReady)
        let testsOnly = try semaphore.acquire(.of(secondResource: 5))
        XCTAssertTrue(testsOnly.isReady)
        XCTAssertEqual(semaphore.availableResources, .of(firstResource: 2, secondResource: 2))
        
        let combined = try semaphore.acquire(.of(firstResource: 4, secondResource: 4))
        XCTAssertFalse(combined.isReady)
        XCTAssertEqual(semaphore.queueLength, 1)
        XCTAssertEqual(semaphore.availableResources, .of(firstResource: 2, secondResource: 2))
        
        // release resources of simulatorsOnly operation
        try semaphore.release(.of(firstResource: 5))
        XCTAssertEqual(semaphore.availableResources, .of(firstResource: 7, secondResource: 2))
        XCTAssertFalse(combined.isReady)
        
        // release resources of testsOnly operation, making available resources capable of performing combined operation
        try semaphore.release(.of(secondResource: 5))
        XCTAssertTrue(combined.isReady)
        XCTAssertEqual(semaphore.availableResources, .of(firstResource: 3, secondResource: 3))
    }
}

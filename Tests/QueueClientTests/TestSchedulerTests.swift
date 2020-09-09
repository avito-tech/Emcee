import Dispatch
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class TestSchedulerTests: XCTestCase {
    private lazy var scheduler = TestSchedulerImpl(requestSender: requestSender)
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    private let expectation = XCTestExpectation(description: "Response provided")
    private let requestSender = FakeRequestSender()
    private let workerId: WorkerId = "workerId"
    private lazy var prioritizedJob = PrioritizedJob(
        jobGroupId: "group",
        jobGroupPriority: .lowest,
        jobId: "job",
        jobPriority: .highest
    )
    
    func test___success_scenario() {
        requestSender.result = ScheduleTestsResponse.scheduledTests
        
        requestSender.validateRequest = { sender in
            guard let scheduleTestsRequest = sender.request as? ScheduleTestsRequest else {
                self.failTest("Unexpected request")
            }
            
            XCTAssertEqual(
                scheduleTestsRequest.payload,
                ScheduleTestsPayload(
                    prioritizedJob: self.prioritizedJob,
                    scheduleStrategy: .unsplit,
                    testEntryConfigurations: []
                )
            )
        }
        
        scheduler.scheduleTests(
            prioritizedJob: prioritizedJob,
            scheduleStrategy: .unsplit,
            testEntryConfigurations: [],
            callbackQueue: callbackQueue,
            completion: { (response: Either<Void, Error>) in
                self.assertDoesNotThrow {
                    try response.dematerialize()
                }
                self.expectation.fulfill()
            }
        )
        
        wait(for: [expectation], timeout: 15)
    }
    
    func test___error_scenario() {
        requestSender.requestSenderError = .noData
        
        scheduler.scheduleTests(
            prioritizedJob: prioritizedJob,
            scheduleStrategy: .individual,
            testEntryConfigurations: [],
            callbackQueue: callbackQueue,
            completion: { response in
                XCTAssertTrue(response.isError)
                self.expectation.fulfill()
            }
        )
        
        wait(for: [expectation], timeout: 5)
    }
}

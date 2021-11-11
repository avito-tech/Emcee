import Dispatch
import MetricsExtensions
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import ScheduleStrategy
import TestHelpers
import Types
import XCTest

final class TestSchedulerTests: XCTestCase {
    private lazy var scheduler = TestSchedulerImpl(
        logger: .noOp,
        requestSender: requestSender
    )
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    private let expectation = XCTestExpectation(description: "Response provided")
    private let requestSender = FakeRequestSender()
    private lazy var individualScheduleStrategy = ScheduleStrategy(testSplitterType: .individual)
    private lazy var unsplitScheduleStrategy = ScheduleStrategy(testSplitterType: .unsplit)
    private lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "group",
        jobGroupPriority: .lowest,
        jobId: "job",
        jobPriority: .highest
    )
    
    func test___success_scenario() {
        requestSender.result = ScheduleTestsResponse.scheduledTests
        
        requestSender.validateRequest = { sender in
            guard let scheduleTestsRequest = sender.request as? ScheduleTestsRequest else {
                failTest("Unexpected request")
            }
            
            XCTAssertEqual(
                scheduleTestsRequest.payload,
                ScheduleTestsPayload(
                    prioritizedJob: self.prioritizedJob,
                    scheduleStrategy: self.unsplitScheduleStrategy,
                    testEntryConfigurations: []
                )
            )
        }
        
        scheduler.scheduleTests(
            prioritizedJob: prioritizedJob,
            scheduleStrategy: unsplitScheduleStrategy,
            testEntryConfigurations: [],
            callbackQueue: callbackQueue,
            completion: { (response: Either<Void, Error>) in
                assertDoesNotThrow {
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
            scheduleStrategy: individualScheduleStrategy,
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

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
import QueueModelsTestHelpers

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
    private lazy var similarlyConfiguredTestEntries = SimilarlyConfiguredTestEntries(
        testEntries: [],
        testEntryConfiguration: TestEntryConfigurationFixtures()
            .testEntryConfiguration()
    )
    
    func test___success_scenario() {
        requestSender.result = ScheduleTestsResponse.scheduledTests
        
        requestSender.validateRequest = { sender in
            guard let scheduleTestsRequest = sender.request as? ScheduleTestsRequest else {
                failTest("Unexpected request")
            }
            
            assert {
                scheduleTestsRequest.payload
            } equals: {
                ScheduleTestsPayload(
                    prioritizedJob: self.prioritizedJob,
                    scheduleStrategy: self.unsplitScheduleStrategy,
                    similarlyConfiguredTestEntries: self.similarlyConfiguredTestEntries
                )
            }
        }
        
        scheduler.scheduleTests(
            prioritizedJob: prioritizedJob,
            scheduleStrategy: unsplitScheduleStrategy,
            similarlyConfiguredTestEntries: similarlyConfiguredTestEntries,
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
            similarlyConfiguredTestEntries: similarlyConfiguredTestEntries,
            callbackQueue: callbackQueue,
            completion: { response in
                XCTAssertTrue(response.isError)
                self.expectation.fulfill()
            }
        )
        
        wait(for: [expectation], timeout: 5)
    }
}

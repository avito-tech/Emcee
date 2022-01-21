import Dispatch
import LogStreamingModels
import MetricsExtensions
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import ScheduleStrategy
import SocketModels
import TestHelpers
import Types
import XCTest

final class TestSchedulerTests: XCTestCase {
    private lazy var scheduler = TestSchedulerImpl(
        logger: .noOp,
        requestSender: requestSender
    )
    private let clientDetails = ClientDetails(
        socketAddress: SocketAddress(host: "doesnotmatter", port: 42),
        clientLogStreamingMode: .disabled
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
                    clientDetails: self.clientDetails,
                    prioritizedJob: self.prioritizedJob,
                    scheduleStrategy: self.unsplitScheduleStrategy,
                    testEntryConfigurations: []
                )
            )
        }
        
        scheduler.scheduleTests(
            clientDetails: clientDetails,
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
            clientDetails: clientDetails,
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

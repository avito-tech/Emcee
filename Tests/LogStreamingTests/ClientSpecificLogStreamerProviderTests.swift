import EmceeLoggingModels
import EmceeLoggingTestHelpers
import Foundation
import LogStreaming
import LogStreamingModels
import LogStreamingTestHelpers
import QueueModels
import RequestSender
import RequestSenderTestHelpers
import SocketModels
import TestHelpers
import XCTest

final class ClientSpecificLogStreamerProviderTests: XCTestCase {
    private lazy var queue = DispatchQueue(label: "queue")
    private lazy var logEntrySenderProvider = FakeLogEntrySenderProvider()
    private lazy var clientDetailsHolder = ClientDetailsHolderImpl()
    private lazy var clientSpecificLogStreamerProvider = ClientSpecificLogStreamerProviderImpl(
        clientDetailsHolder: clientDetailsHolder,
        logger: .noOp,
        logEntrySenderProvider: logEntrySenderProvider,
        queue: queue,
        willSendLogEntry: {
            let expectation = XCTestExpectation()
            self.allSendInvocationExpectations.append(expectation)
            self.pendingSendInvocationExpectations.append(expectation)
        },
        didSendLogEntry: { _ in
            let pending = self.pendingSendInvocationExpectations.removeLast()
            pending.fulfill()
        }
    )
    
    private let bucketId: BucketId = "BUCKET_ID"
    private let clientSocketAddress = SocketAddress(host: "doesntmatter.example.com", port: 12345)
    private let bucketSpecificLogEntry = LogEntryFixture(message: "bucket specific log").logEntry()
    private let globalLogEntry = LogEntryFixture(message: "global log").logEntry()
    
    private var allSendInvocationExpectations = [XCTestExpectation]()
    private var pendingSendInvocationExpectations = [XCTestExpectation]()
    private var didSendInvocations = [Error?]()
    
    func test___streaming_to_client___all_logs___streams_job_specific_logs() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .all)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToClientCreatedBucketId(bucketId: bucketId)
        streamer.stream(logEntry: bucketSpecificLogEntry)
        
        assert {
            logEntrySenderProvider.providedFakeLogEntrySenders.map { $0.invocations }
        } equals: {
            [
                [bucketSpecificLogEntry]
            ]
        }
    }
    
    func test___streaming_to_client___all_logs___streams_global_logs() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .all)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        streamer.stream(logEntry: bucketSpecificLogEntry)
        
        assert {
            logEntrySenderProvider.providedFakeLogEntrySenders.map { $0.invocations }
        } equals: {
            [
                [bucketSpecificLogEntry]
            ]
        }
    }
    
    func test___streaming_to_client___only_job_specific_logs___streams_job_specific_logs() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .jobSpecific)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToClientCreatedBucketId(bucketId: bucketId)
        streamer.stream(logEntry: bucketSpecificLogEntry)
        
        assert {
            logEntrySenderProvider.providedFakeLogEntrySenders.map { $0.invocations }
        } equals: {
            [
                [bucketSpecificLogEntry]
            ]
        }
    }
    
    func test___streaming_to_client___only_job_specific_logs___does_not_stream_global_logs() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .jobSpecific)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        streamer.stream(logEntry: bucketSpecificLogEntry)
        
        assert {
            logEntrySenderProvider.providedFakeLogEntrySenders.map { $0.invocations }
        } equals: {
            []
        }
    }
    
    func test___streaming_to_client___when_all_logs_disabled___does_not_stream_job_specific_logs() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .disabled)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToClientCreatedBucketId(bucketId: bucketId)
        streamer.stream(logEntry: bucketSpecificLogEntry)
        
        assert {
            logEntrySenderProvider.providedFakeLogEntrySenders.map { $0.invocations }
        } equals: {
            []
        }
    }
    
    func test___streaming_to_client___when_all_logs_disabled___does_not_stream_global_logs() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .disabled)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        streamer.stream(logEntry: bucketSpecificLogEntry)
        
        assert {
            logEntrySenderProvider.providedFakeLogEntrySenders.map { $0.invocations }
        } equals: {
            []
        }
    }
    
    func test___reporting_will_log() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .all)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        streamer.stream(logEntry: bucketSpecificLogEntry)
        streamer.stream(logEntry: globalLogEntry)
        
        assert { allSendInvocationExpectations.count } equals: { 2 }
    }
    
    func test___reporting_did_log() {
        associate(bucketId: bucketId, with: clientSocketAddress, clientLogStreamingMode: .all)
        
        let streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        streamer.stream(logEntry: bucketSpecificLogEntry)
        streamer.stream(logEntry: globalLogEntry)
        
        wait(for: allSendInvocationExpectations, timeout: 15)
    }
    
    private func associate(bucketId: BucketId, with clientSocketAddress: SocketAddress, clientLogStreamingMode: ClientLogStreamingMode) {
        clientDetailsHolder.associate(
            bucketId: bucketId,
            clientDetails: ClientDetails(
                socketAddress: clientSocketAddress,
                clientLogStreamingMode: clientLogStreamingMode
            )
        )
    }
}

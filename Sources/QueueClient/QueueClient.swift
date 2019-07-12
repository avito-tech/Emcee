import Dispatch
import Extensions
import Foundation
import Logging
import Models
import RESTMethods

public final class QueueClient {
    public weak var delegate: QueueClientDelegate?
    private let queueServerAddress: SocketAddress
    private let urlSession = URLSession(configuration: URLSessionConfiguration.default)
    private let encoder = JSONEncoder.pretty()
    private var isClosed = false
    
    public init(queueServerAddress: SocketAddress) {
        self.queueServerAddress = queueServerAddress
    }
    
    deinit {
        close()
    }
    
    public func registerWithServer(workerId: WorkerId) throws {
        try sendRequest(
            .registerWorker,
            payload: RegisterWorkerRequest(workerId: workerId),
            completionHandler: handleRegisterWorkerResponse
        )
    }
    
    public func close() {
        Logger.verboseDebug("Invalidating queue client URL session")
        urlSession.finishTasksAndInvalidate()
        isClosed = true
    }
    
    /// Request id is a unique request identifier that could be used to retry bucket fetch in case if
    /// request has failed. Server is expected to return the same bucket if request id + worker id pair
    /// match for sequential requests.
    /// Apple's guide on handling Handling "The network connection was lost" errors:
    /// https://developer.apple.com/library/archive/qa/qa1941/_index.html
    public func fetchBucket(
        requestId: RequestId,
        workerId: WorkerId,
        requestSignature: RequestSignature
    ) throws {
        try sendRequest(
            .getBucket,
            payload: DequeueBucketRequest(
                workerId: workerId,
                requestId: requestId,
                requestSignature: requestSignature
            ),
            completionHandler: handleFetchBucketResponse
        )
    }
    
    public func send(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId,
        requestSignature: RequestSignature
    ) throws {
        try sendRequest(
            .bucketResult,
            payload: PushBucketResultRequest(
                workerId: workerId,
                requestId: requestId,
                testingResult: testingResult,
                requestSignature: requestSignature
            ),
            completionHandler: handleSendBucketResultResponse
        )
    }
    
    public func reportAlive(
        bucketIdsBeingProcessedProvider: @autoclosure () -> (Set<BucketId>),
        workerId: WorkerId,
        requestSignature: RequestSignature,
        completion: @escaping (Either<ReportAliveResponse, QueueClientError>) -> ()
    ) throws {
        try sendRequestWithCallback(
            .reportAlive,
            payload: ReportAliveRequest(
                workerId: workerId,
                bucketIdsBeingProcessed: bucketIdsBeingProcessedProvider(),
                requestSignature: requestSignature
            ),
            callback: completion
        )
    }
    
    public func fetchQueueServerVersion() throws {
        try sendRequest(
            .queueVersion,
            payload: QueueVersionRequest(),
            completionHandler: handleQueueServerVersion
        )
    }
    
    public func scheduleTests(
        prioritizedJob: PrioritizedJob,
        testEntryConfigurations: [TestEntryConfiguration],
        requestId: RequestId)
        throws
    {
        try sendRequest(
            .scheduleTests,
            payload: ScheduleTestsRequest(
                requestId: requestId,
                prioritizedJob: prioritizedJob,
                testEntryConfigurations: testEntryConfigurations
            ),
            completionHandler: handleScheduleTestsResponse
        )
    }
    
    public func fetchJobResults(jobId: JobId) throws {
        try sendRequest(
            .jobResults,
            payload: JobResultsRequest(jobId: jobId),
            completionHandler: handleJobResultsResponse
        )
    }
    
    public func fetchJobState(jobId: JobId) throws {
        try sendRequest(
            .jobState,
            payload: JobStateRequest(jobId: jobId),
            completionHandler: handleJobStateResponse
        )
    }
    
    public func deleteJob(jobId: JobId) throws {
        try sendRequest(
            .jobDelete,
            payload: JobDeleteRequest(jobId: jobId),
            completionHandler: handleJobDeleteResponse
        )
    }

    // MARK: - Request Generation
    
    private func sendRequest<Payload, Response>(
        _ restMethod: RESTMethod,
        payload: Payload,
        completionHandler: @escaping (Response) throws -> ())
        throws where Payload : Encodable, Response : Decodable
    {
        guard !isClosed else { throw QueueClientError.queueClientIsClosed(restMethod) }
        let url = createUrl(restMethod: restMethod)
        let jsonData = try encoder.encode(payload)
        if let stringJson = String(data: jsonData, encoding: .utf8) {
            Logger.verboseDebug("Sending request to \(url): \(stringJson)")
        } else {
            Logger.verboseDebug("Sending request to \(url): unable to get string for json data \(jsonData.count) bytes")
        }
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: .infinity)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Content-Type", forHTTPHeaderField: "application/json")
        urlRequest.httpBody = jsonData
        let dataTask = urlSession.dataTask(with: urlRequest) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.delegate?.queueClient(strongSelf, didFailWithError: QueueClientError.communicationError(error)); return
            }
            guard let data = data else {
                strongSelf.delegate?.queueClient(strongSelf, didFailWithError: QueueClientError.noData); return
            }
            do {
                try completionHandler(try JSONDecoder().decode(Response.self, from: data))
            } catch {
                strongSelf.delegate?.queueClient(strongSelf, didFailWithError: QueueClientError.parseError(error, data)); return
            }
        }
        dataTask.resume()
    }
    
    private func sendRequestWithCallback<Payload, Response>(
        _ restMethod: RESTMethod,
        payload: Payload,
        callback: @escaping (Either<Response, QueueClientError>) -> ()
    ) throws where Payload : Encodable, Response : Decodable {
        guard !isClosed else { throw QueueClientError.queueClientIsClosed(restMethod) }
        let url = createUrl(restMethod: restMethod)
        let jsonData = try encoder.encode(payload)
        if let stringJson = String(data: jsonData, encoding: .utf8) {
            Logger.verboseDebug("Sending request to \(url): \(stringJson)")
        } else {
            Logger.verboseDebug("Sending request to \(url): unable to get string for json data \(jsonData.count) bytes")
        }
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: .infinity)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Content-Type", forHTTPHeaderField: "application/json")
        urlRequest.httpBody = jsonData
        let dataTask = urlSession.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                callback(
                    .error(QueueClientError.communicationError(error))
                )
            } else if let data = data {
                do {
                    callback(
                        .success(try JSONDecoder().decode(Response.self, from: data))
                    )
                } catch {
                    callback(
                        .error(QueueClientError.parseError(error, data))
                    )
                }
            } else {
                callback(
                    .error(QueueClientError.noData)
                )
            }
        }
        dataTask.resume()
    }
    
    private func createUrl(restMethod: RESTMethod) -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = queueServerAddress.host
        components.port = queueServerAddress.port
        components.path = restMethod.withPrependingSlash
        guard let url = components.url else {
            Logger.fatal("Unable to convert components to url: \(components)")
        }
        return url
    }
    
    // MARK: - Response Handlers
    
    private func handleRegisterWorkerResponse(response: RegisterWorkerResponse) {
        switch response {
        case .workerRegisterSuccess(let workerConfiguration):
            delegate?.queueClient(self, didReceiveWorkerConfiguration: workerConfiguration)
        }
    }
    
    private func handleFetchBucketResponse(response: DequeueBucketResponse) {
        switch response {
        case .bucketDequeued(let bucket):
            delegate?.queueClient(self, didFetchBucket: bucket)
        case .checkAgainLater(let checkAfter):
            delegate?.queueClient(self, fetchBucketLaterAfter: checkAfter)
        case .queueIsEmpty:
            delegate?.queueClientQueueIsEmpty(self)
        case .workerIsNotAlive:
            delegate?.queueClientWorkerConsideredNotAlive(self)
        case .workerIsBlocked:
            delegate?.queueClientWorkerHasBeenBlocked(self)
        }
    }
    
    private func handleSendBucketResultResponse(response: BucketResultAcceptResponse) {
        switch response {
        case .bucketResultAccepted(let bucketId):
            delegate?.queueClient(self, serverDidAcceptBucketResult: bucketId)
        }
    }
    
    private func handleAlivenessResponse(response: ReportAliveResponse) {
        switch response {
        case .aliveReportAccepted:
            delegate?.queueClientWorkerHasBeenIndicatedAsAlive(self)
        }
    }
    
    private func handleQueueServerVersion(response: QueueVersionResponse) {
        switch response {
        case .queueVersion(let version):
            delegate?.queueClient(self, didFetchQueueServerVersion: version)
        }
    }
    
    private func handleScheduleTestsResponse(response: ScheduleTestsResponse) {
        switch response {
        case .scheduledTests(let requestId):
            delegate?.queueClientDidScheduleTests(self, requestId: requestId)
        }
    }
    
    private func handleJobStateResponse(response: JobStateResponse) {
        delegate?.queueClient(self, didFetchJobState: response.jobState)
    }
    
    private func handleJobResultsResponse(response: JobResultsResponse) {
        delegate?.queueClient(self, didFetchJobResults: response.jobResults)
    }
    
    private func handleJobDeleteResponse(response: JobDeleteResponse) {
        delegate?.queueClient(self, didDeleteJob: response.jobId)
    }
}

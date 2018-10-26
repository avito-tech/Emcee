import Dispatch
import Foundation
import RESTMethods
import Models
import Logging

public final class QueueClient {
    public weak var delegate: QueueClientDelegate?
    private let serverAddress: String
    private let serverPort: Int
    private let workerId: String
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private let reportingAliveQueue = DispatchQueue(label: "ru.avito.runner.QueueClient")
    private var reportingAliveTimer: DispatchSourceTimer?
    
    public init(serverAddress: String, serverPort: Int, workerId: String) {
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.workerId = workerId
        urlSession = URLSession(configuration: URLSessionConfiguration.default)
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        decoder = JSONDecoder()
    }
    
    deinit {
        close()
    }
    
    public func registerWithServer() throws {
        try sendRequest(
            .registerWorker,
            payload: RegisterWorkerRequest(workerId: workerId),
            completionHandler: handleRegisterWorkerResponse)
    }
    
    public func close() {
        urlSession.invalidateAndCancel()
        reportingAliveTimer?.cancel()
    }
    
    /**
     * Request id is a unique request identifier that could be used to retry bucket fetch in case if
     * request has failed. https://developer.apple.com/library/archive/qa/qa1941/_index.html
     */
    public func fetchBucket(requestId: String) throws {
        try sendRequest(
            .getBucket,
            payload: BucketFetchRequest(workerId: workerId, requestId: requestId),
            completionHandler: handleFetchBucketResponse)
    }
    
    public func send(testingResult: TestingResult, requestId: String) throws {
        let resultRequest = BucketResultRequest(workerId: workerId, requestId: requestId, testingResult: testingResult)
        try sendRequest(.bucketResult, payload: resultRequest, completionHandler: handleSendBucketResultResponse)
    }
    
    // MARK: - Request Generation
    
    private func sendRequest<T>(
        _ restMethod: RESTMethod,
        payload: T,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> ())
        throws where T : Encodable
    {
        let jsonData = try encoder.encode(payload)
        if let stringJson = String(data: jsonData, encoding: .utf8) {
            log("Sending request to \(restMethod.withPrependingSlash): \(stringJson)")
        } else {
            log("Sending request to \(restMethod.withPrependingSlash): unable to get string for json data \(jsonData.count) bytes")
        }
        var urlRequest = URLRequest(url: url(restMethod), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: .infinity)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Content-Type", forHTTPHeaderField: "application/json")
        urlRequest.httpBody = jsonData
        let dataTask = urlSession.dataTask(with: urlRequest, completionHandler: completionHandler)
        dataTask.resume()
    }
    
    private func url(_ method: RESTMethod) -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = serverAddress
        components.port = serverPort
        components.path = RESTMethod.getBucket.withPrependingSlash
        components.path = method.withPrependingSlash
        guard let url = components.url else {
            let error = "Unable to convert components to url: \(components)"
            log(error, color: .red)
            fatalError(error)
        }
        return url
    }
    
    // MARK: - Response Handlers
    
    private func handleRegisterWorkerResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            delegate?.queueClient(self, didFailWithError: QueueClientError.communicationError(error)); return
        }
        guard let data = data else {
            delegate?.queueClient(self, didFailWithError: QueueClientError.noData); return
        }
        do {
            let response = try decoder.decode(RESTResponse.self, from: data)
            switch response {
            case .workerRegisterSuccess(let workerConfiguration):
                delegate?.queueClient(self, didReceiveWorkerConfiguration: workerConfiguration)
                startReportingWorkerIsAlive(interval: workerConfiguration.reportAliveInterval)
            default:
                delegate?.queueClient(self, didFailWithError: QueueClientError.unexpectedResponse(data))
            }
        } catch {
            delegate?.queueClient(self, didFailWithError: QueueClientError.parseError(error, data)); return
        }
    }
    
    private func handleFetchBucketResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            delegate?.queueClient(self, didFailWithError: QueueClientError.communicationError(error)); return
        }
        guard let data = data else {
            delegate?.queueClient(self, didFailWithError: QueueClientError.noData); return
        }

        do {
            let response = try decoder.decode(RESTResponse.self, from: data)
            switch response {
            case .bucketDequeued(let bucket):
                delegate?.queueClient(self, didFetchBucket: bucket)
            case .checkAgainLater(let checkAfter):
                delegate?.queueClient(self, fetchBucketLaterAfter: checkAfter)
            case .queueIsEmpty:
                delegate?.queueClientQueueIsEmpty(self)
            case .workerBlocked:
                delegate?.queueClientWorkerHasBeenBlocked(self)
            default:
                delegate?.queueClient(self, didFailWithError: .unexpectedResponse(data))
            }
        } catch {
            delegate?.queueClient(self, didFailWithError: .parseError(error, data))
        }
    }
    
    private func handleSendBucketResultResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            delegate?.queueClient(self, didFailWithError: QueueClientError.communicationError(error)); return
        }
        guard let data = data else {
            delegate?.queueClient(self, didFailWithError: QueueClientError.noData); return
        }
        
        do {
            let response = try decoder.decode(RESTResponse.self, from: data)
            switch response {
            case .bucketResultAccepted(let bucketId):
                delegate?.queueClient(self, serverDidAcceptBucketResult: bucketId)
            default:
                delegate?.queueClient(self, didFailWithError: QueueClientError.unexpectedResponse(data))
            }
        } catch {
            delegate?.queueClient(self, didFailWithError: QueueClientError.parseError(error, data)); return
        }
    }
    
    // MARK: - Reporting Worker is Alive
    
    private func reportAlive() throws {
        try sendRequest(
            .reportAlive,
            payload: ReportAliveRequest(workerId: workerId)) {_, urlResponse,_ in
                guard let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode == 202 else {
                    log("Failed to send report alive request: got invalid reponse: \(String(reflecting: urlResponse))")
                    return
                }
                log("Sent report alive request")
        }
    }
    
    private func startReportingWorkerIsAlive(interval: TimeInterval) {
        let timer = DispatchSource.makeTimerSource(queue: reportingAliveQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(Int(interval * 1000.0)), leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            if let strongSelf = self {
                do {
                    try strongSelf.reportAlive()
                } catch {
                    log("Error: can't report alive: \(error)")
                }
            }
        }
        timer.resume()
        reportingAliveTimer = timer
    }
}

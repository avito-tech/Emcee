import Foundation
import EmceeLogging
import SocketModels
import Types

public final class RequestSenderImpl: RequestSender {
    private let logger: ContextualLogger
    private let urlSession: URLSession
    private let queueServerAddress: SocketAddress
    private var isClosed = false

    public init(
        logger: ContextualLogger,
        urlSession: URLSession,
        queueServerAddress: SocketAddress
    ) {
        self.logger = logger
        self.urlSession = urlSession
        self.queueServerAddress = queueServerAddress
    }
    
    public func close() {
        logger.debug("Invalidating URL session")
        urlSession.finishTasksAndInvalidate()
        isClosed = true
    }

    public func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        credentials: Credentials?,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    ) {
        do {
            try sendRequest(
                request: request,
                credentials: credentials,
                callbackQueue: callbackQueue,
                callback: callback
            )
        } catch {
            callbackQueue.async {
                callback(.error(.cannotIssueRequest(error)))
            }
        }
    }
    
    private func sendRequest<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        credentials: Credentials?,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    ) throws {
        let url = try createUrl(pathWithSlash: request.pathWithLeadingSlash)
        logger.debug("Sending request to \(url)")
        
        guard !isClosed else {
            throw RequestSenderError.sessionIsClosed(url)
        }

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: .infinity)
        urlRequest.addValue("Content-Type", forHTTPHeaderField: "application/json")
        urlRequest.httpMethod = request.httpMethod.value
        urlRequest.httpBody = try buildHttpBody(payload: request.payload)
        urlRequest.timeoutInterval = request.timeout

        if let credentials = credentials {
            let loginString = try "\(credentials.username):\(credentials.password)".base64()
            urlRequest.setValue("Basic \(loginString)", forHTTPHeaderField: "Authorization")
        }

        launchDataTask(url: url, urlRequest: urlRequest, callbackQueue: callbackQueue, callback: callback)
    }

    private func buildHttpBody<PayloadType: Encodable>(payload: PayloadType?) throws -> Data? {
        guard let payload = payload else {
            return nil
        }

        let jsonData = try JSONEncoder.pretty().encode(payload)
        
        if let stringJson = String(data: jsonData, encoding: .utf8) {
            logger.debug("Payload: \(stringJson)")
        } else {
            logger.debug("Unable to get string for payload data \(jsonData.count) bytes")
        }

        return jsonData
    }

    private func launchDataTask<ResponseType: Decodable>(
        url: URL,
        urlRequest: URLRequest,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<ResponseType, RequestSenderError>) -> ()
    ) {
        let logger = self.logger.withMetadata(key: "url", value: "\(url)")
        
        let dataTask = urlSession.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                logger.debug("Failed to perform request to \(url): \(error)")
                callbackQueue.async { callback(.error(.communicationError(error))) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                guard 200 ... 299 ~= httpResponse.statusCode else {
                    callbackQueue.async {
                        callback(
                            .error(
                                .badStatusCode(httpResponse.statusCode, body: data)
                            )
                        )
                    }
                    return
                }
            }

            if let data = data {
                do {
                    let decodedObject = try JSONDecoder().decode(ResponseType.self, from: data)
                    logger.debug("Successfully decoded object from response of request to \(url): \(decodedObject)")
                    callbackQueue.async { callback(.success(decodedObject)) }
                } catch {
                    logger.debug("Failed to decode object from response of request to \(url): \(error)")
                    callbackQueue.async { callback(.error(.parseError(error, data))) }
                }
            } else {
                logger.debug("Failed to process response from request to \(url): response has no data")
                callbackQueue.async { callback(.error(.noData)) }
            }
        }
        dataTask.resume()
    }
    
    private func createUrl(pathWithSlash: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = queueServerAddress.host
        components.port = queueServerAddress.port.value
        components.path = pathWithSlash
        guard let url = components.url else {
            throw RequestSenderError.unableToCreateUrl(components)
        }
        return url
    }
}

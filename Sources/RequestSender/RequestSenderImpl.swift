import Extensions
import Foundation
import Logging
import Models

public final class RequestSenderImpl: RequestSender {
    private let urlSession: URLSession
    private let queueServerAddress: SocketAddress
    private var isClosed = false

    public init(urlSession: URLSession, queueServerAddress: SocketAddress) {
        self.urlSession = urlSession
        self.queueServerAddress = queueServerAddress
    }
    
    public func close() {
        Logger.verboseDebug("Invalidating URL session")
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
        Logger.verboseDebug("Sending request to \(url)")
        
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
            Logger.verboseDebug("Payload: \(stringJson)")
        } else {
            Logger.verboseDebug("Unable to get string for payload data \(jsonData.count) bytes")
        }

        return jsonData
    }

    private func launchDataTask<ResponseType: Decodable>(
        url: URL,
        urlRequest: URLRequest,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<ResponseType, RequestSenderError>) -> ()
    ) {
        let dataTask = urlSession.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                Logger.verboseDebug("Failed to perform request to \(url): \(error)")
                callbackQueue.async { callback(.error(.communicationError(error))) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                guard 200 ... 299 ~= httpResponse.statusCode else {
                    callbackQueue.async { callback(.error(.badStatusCode(httpResponse.statusCode))) }
                    return
                }
            }

            if let data = data {
                do {
                    let decodedObject = try JSONDecoder().decode(ResponseType.self, from: data)
                    Logger.verboseDebug("Successfully decoded object from response of request to \(url): \(decodedObject)")
                    callbackQueue.async { callback(.success(decodedObject)) }
                } catch {
                    Logger.verboseDebug("Failed to decode object from response of request to \(url): \(error)")
                    callbackQueue.async { callback(.error(.parseError(error, data))) }
                }
            } else {
                Logger.verboseDebug("Failed to perform request to \(url): response has no data")
                callbackQueue.async { callback(.error(.noData)) }
            }
        }
        dataTask.resume()
    }
    
    private func createUrl(pathWithSlash: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = queueServerAddress.host
        components.port = queueServerAddress.port
        components.path = pathWithSlash
        guard let url = components.url else {
            throw RequestSenderError.unableToCreateUrl(components)
        }
        return url
    }
}

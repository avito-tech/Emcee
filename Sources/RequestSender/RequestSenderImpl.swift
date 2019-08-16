import Extensions
import Foundation
import Logging
import Models

public final class RequestSenderImpl: RequestSender {
    private let encoder = JSONEncoder.pretty()
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
    
    public func sendRequestWithCallback<Payload, Response>(
        pathWithSlash: String,
        payload: Payload,
        callback: @escaping (Either<Response, RequestSenderError>) -> ()
    ) throws where Payload : Encodable, Response : Decodable {
        let url = createUrl(pathWithSlash: pathWithSlash)
        
        guard !isClosed else {
            throw RequestSenderError.sessionIsClosed(url)
        }
        
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
                    .error(RequestSenderError.communicationError(error))
                )
            } else if let data = data {
                do {
                    callback(
                        .success(try JSONDecoder().decode(Response.self, from: data))
                    )
                } catch {
                    callback(
                        .error(RequestSenderError.parseError(error, data))
                    )
                }
            } else {
                callback(
                    .error(RequestSenderError.noData)
                )
            }
        }
        dataTask.resume()
    }
    
    private func createUrl(pathWithSlash: String) -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = queueServerAddress.host
        components.port = queueServerAddress.port
        components.path = pathWithSlash
        guard let url = components.url else {
            Logger.fatal("Unable to convert components to url: \(components)")
        }
        return url
    }
}

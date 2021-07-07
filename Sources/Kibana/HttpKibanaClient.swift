import DateProvider
import Foundation


public final class HttpKibanaClient: KibanaClient {
    private let dateProvider: DateProvider
    private let endpoints: [KibanaHttpEndpoint]
    private let indexPattern: String
    private let urlSession: URLSession
    private let jsonEncoder = JSONEncoder()
    
    private let timestampDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    public init(
        dateProvider: DateProvider,
        endpoints: [KibanaHttpEndpoint],
        indexPattern: String,
        urlSession: URLSession
    ) throws {
        guard !endpoints.isEmpty else { throw KibanaClientEndpointError() }
        
        self.dateProvider = dateProvider
        self.endpoints = endpoints
        self.indexPattern = indexPattern
        self.urlSession = urlSession
    }
    
    public struct KibanaClientEndpointError: Error, CustomStringConvertible {
        public var description: String {
            "No endpoint provided for kibana client. At least a single endpoint must be provided."
        }
    }
    
    public func send(
        level: String,
        message: String,
        metadata: [String : String],
        completion: @escaping (Error?) -> ()
    ) throws {
        let timestamp = dateProvider.currentDate()
        
        var params: [String: String] = [
            "@timestamp": timestampDateFormatter.string(from: timestamp),
            "level": level,
            "message": message,
        ]
        
        params.merge(metadata) { current, _ in current }
        
        guard let endpoint = endpoints.randomElement() else { throw KibanaClientEndpointError() }
        
        var request = URLRequest(
            url: try endpoint.singleEventUrl(
                indexPattern: indexPattern
            )
        )
        request.httpMethod = "POST"
        request.httpBody = try jsonEncoder.encode(params)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = urlSession.dataTask(with: request) { _, _, error in
            completion(error)
        }
        task.resume()
    }
}


import DateProvider
import Foundation
import SocketModels

public protocol KibanaClient {
    func send(level: String, message: String, metadata: [String: String], completion: @escaping (Error?) -> ()) throws
}

public struct KibanaHttpEndpoint {
    public enum Scheme: String {
        case http
        case https
    }
    
    public let scheme: Scheme
    public let socketAddress: SocketAddress
    
    public static func from(url: URL) throws -> Self {
        struct UnsupportedUrlError: Error, CustomStringConvertible {
            let url: URL
            var description: String { "URL \(url) cannot be used as a HTTP Kibana endpoint" }
        }
        
        let scheme: Scheme
        var port: SocketModels.Port
        switch url.scheme {
        case "http":
            scheme = .http
            port = 80
        case "https":
            scheme = .https
            port = 443
        default:
            throw UnsupportedUrlError(url: url)
        }
        guard let host = url.host else { throw UnsupportedUrlError(url: url) }
        if let specificPort = url.port {
            port = SocketModels.Port(value: specificPort)
        }
        
        return Self(scheme: scheme, socketAddress: SocketAddress(host: host, port: port))
    }
    
    public static func http(_ socketAddress: SocketAddress) -> Self {
        KibanaHttpEndpoint(scheme: .http, socketAddress: socketAddress)
    }
    
    public static func https(_ socketAddress: SocketAddress) -> Self {
        KibanaHttpEndpoint(scheme: .https, socketAddress: socketAddress)
    }
    
    public func singleEventUrl(indexPattern: String, date: Date) -> URL {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = socketAddress.host
        components.port = socketAddress.port.value
        components.path = "/\(indexPattern)/_doc"
        return components.url!
    }
}

public final class HttpKibanaClient: KibanaClient {
    private let dateProvider: DateProvider
    private let endpoints: [KibanaHttpEndpoint]
    private let indexPattern: String
    private let urlSession: URLSession
    private let jsonEncoder = JSONEncoder()
    
    private let timestampDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()
    
    public init(
        dateProvider: DateProvider,
        endpoints: [KibanaHttpEndpoint],
        indexPattern: String,
        urlSession: URLSession
    ) {
        self.dateProvider = dateProvider
        self.endpoints = endpoints
        self.indexPattern = indexPattern
        self.urlSession = urlSession
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
        
        var request = URLRequest(
            url: endpoints.randomElement()!.singleEventUrl(
                indexPattern: indexPattern,
                date: timestamp
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

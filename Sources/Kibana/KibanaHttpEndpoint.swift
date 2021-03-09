import Foundation
import SocketModels

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
    
    public func singleEventUrl(indexPattern: String, date: Date) throws -> URL {
        struct FailedToBuildUrlError: Error, CustomStringConvertible {
            let scheme: Scheme
            let socketAddress: SocketAddress
            let path: String
            var description: String { "Cannot build URL with scheme \(scheme), address \(socketAddress), path \(path)" }
        }
        
        let path = "/\(indexPattern)/_doc"
        
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = socketAddress.host
        components.port = socketAddress.port.value
        components.path = path
        guard let url = components.url else {
            throw FailedToBuildUrlError(scheme: scheme, socketAddress: socketAddress, path: path)
        }
        return url
    }
}

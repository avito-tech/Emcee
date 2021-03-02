import Foundation

public struct KibanaConfiguration: Codable, Hashable {
    public let endpoints: [URL]
    public let indexPattern: String
    
    public init(
        endpoints: [URL],
        indexPattern: String
    ) {
        self.endpoints = endpoints
        self.indexPattern = indexPattern
    }
}

public enum HTTPMethod: String, Codable {
    case get
    case post
    case put

    public var value: String {
        return rawValue.uppercased()
    }
}

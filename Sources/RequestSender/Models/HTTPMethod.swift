public enum HTTPMethod: String {
    case get
    case post
    case put

    public var value: String {
        return rawValue.uppercased()
    }
}

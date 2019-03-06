import Foundation

public struct FbXcGenericErrorEvent: Decodable {
    public let errorOrigin: String
    public let domain: String
    public let code: Int
    public let text: String?
    
    public init(errorOrigin: String, domain: String, code: Int, text: String?) {
        self.errorOrigin = errorOrigin
        self.domain = domain
        self.code = code
        self.text = text
    }
}

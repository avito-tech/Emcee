import Foundation

extension String {
    func base64() throws -> String {
        Data(utf8).base64EncodedString()
    }
}

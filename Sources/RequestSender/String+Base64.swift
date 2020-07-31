extension String {
    enum Base64ConversionError: Error {
        case notUTF8Encoding
    }

    func base64() throws -> String {
        guard let data = self.data(using: String.Encoding.utf8) else {
            throw Base64ConversionError.notUTF8Encoding
        }

        return data.base64EncodedString()
    }
}

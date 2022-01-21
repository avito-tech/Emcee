import RunnerModels

public enum XcTestRunAttachmentLifetime: String, CaseIterable {
    
    /// Attachments enabled, but will be deleted for success tests
    case deleteOnSuccess
    
    /// Attachments enabled
    case keepAlways
    
    /// Attachments disabled
    case keepNever
        
    public init(fromRawValue value: String) throws {
        guard let attachmentLifetime = XcTestRunAttachmentLifetime(rawValue: value) else {
            struct UnknownRawValue: Error, CustomStringConvertible {
                let value: String
                var description: String {
                    let possibleValues = XcTestRunAttachmentLifetime.allCases
                        .map { "'\($0.rawValue)'" }
                        .joined(separator: ", ")
                    return "Couldn't init 'XcTestRunAttachmentLifetime' from value: '\(value)'. Possible values: \(possibleValues)"
                }
            }
            throw UnknownRawValue(value: value)
        }
        self = attachmentLifetime
    }
    
    public init(testAttachmentLifetime: TestAttachmentLifetime) {
        switch testAttachmentLifetime {
        case .deleteOnSuccess:
            self = .deleteOnSuccess
        case .keepAlways:
            self = .keepAlways
        case .keepNever:
            self = .keepNever
        }
    }
}

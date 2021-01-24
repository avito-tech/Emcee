import Foundation
 
public struct RSTestFailureIssueSummary: Codable, RSTypedValue, Equatable {
    public static let typeName = "TestFailureIssueSummary"
    
    public let documentLocationInCreatingWorkspace: RSDocumentLocation
    public let issueType: RSString
    public let message: RSString
    public let testCaseName: RSString
    
    public init(
        documentLocationInCreatingWorkspace: RSDocumentLocation,
        issueType: RSString,
        message: RSString,
        testCaseName: RSString
    ) {
        self.documentLocationInCreatingWorkspace = documentLocationInCreatingWorkspace
        self.issueType = issueType
        self.message = message
        self.testCaseName = testCaseName
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        documentLocationInCreatingWorkspace = try container.decode(RSDocumentLocation.self, forKey: .documentLocationInCreatingWorkspace)
        issueType = try container.decode(RSString.self, forKey: .issueType)
        message = try container.decode(RSString.self, forKey: .message)
        testCaseName = try container.decode(RSString.self, forKey: .testCaseName)
    }
}

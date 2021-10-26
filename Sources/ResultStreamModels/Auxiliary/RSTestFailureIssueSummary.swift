import Foundation
 
public struct RSTestFailureIssueSummary: Codable, Equatable, RSTypedValue {
    public static var typeName: String { "TestFailureIssueSummary" }
    public static var superTypeName: String? { "IssueSummary" }
    
    public let issueType: RSString
    public let message: RSString
    public let producingTarget: RSString?
    public let documentLocationInCreatingWorkspace: RSDocumentLocation?
    public let testCaseName: RSString?
    
    public init(
        issueType: RSString,
        message: RSString,
        producingTarget: RSString?,
        documentLocationInCreatingWorkspace: RSDocumentLocation?,
        testCaseName: RSString?
    ) {
        self.issueType = issueType
        self.message = message
        self.producingTarget = producingTarget
        self.documentLocationInCreatingWorkspace = documentLocationInCreatingWorkspace
        self.testCaseName = testCaseName
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        issueType = try container.decode(RSString.self, forKey: .issueType)
        message = try container.decode(RSString.self, forKey: .message)
        producingTarget = try container.decodeIfPresent(RSString.self, forKey: .producingTarget)
        documentLocationInCreatingWorkspace = try container.decodeIfPresent(RSDocumentLocation.self, forKey: .documentLocationInCreatingWorkspace)
        testCaseName = try container.decodeIfPresent(RSString.self, forKey: .testCaseName)
    }
}

import Foundation

public class RSActionTestSummaryIdentifiableObject: Codable, RSTypedValue, Equatable {
    public static func == (lhs: RSActionTestSummaryIdentifiableObject, rhs: RSActionTestSummaryIdentifiableObject) -> Bool {
        lhs.identifier == rhs.identifier && lhs.name == rhs.name
    }
    
    public class var typeName: String { "ActionTestSummaryIdentifiableObject" }
    
    public let identifier: RSString
    public let name: RSString
    
    public init(
        identifier: RSString,
        name: RSString
    ) {
        self.identifier = identifier
        self.name = name
    }
    
    enum CodingKeys: CodingKey {
        case identifier
        case name
    }
        
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(RSString.self, forKey: .identifier)
        name = try container.decode(RSString.self, forKey: .name)
    }
}

public class RSActionTestMetadata: RSActionTestSummaryIdentifiableObject {
    public class override var typeName: String { "ActionTestMetadata" }
    
    public let duration: RSDouble?
    public let testStatus: RSString
    public let summaryRef: RSReference?
    
    public init(
        identifier: RSString,
        name: RSString,
        duration: RSDouble?,
        testStatus: RSString,
        summaryRef: RSReference?
    ) {
        self.duration = duration
        self.testStatus = testStatus
        self.summaryRef = summaryRef
        
        super.init(identifier: identifier, name: name)
    }
    
    enum CodingKeys: CodingKey {
        case duration
        case testStatus
        case summaryRef
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decodeIfPresent(RSDouble.self, forKey: .duration)
        testStatus = try container.decode(RSString.self, forKey: .testStatus)
        summaryRef = try container.decodeIfPresent(RSReference.self, forKey: .summaryRef)
        
        try super.init(from: decoder)
    }
}

public class ActionTestSummaryGroup: RSActionTestSummaryIdentifiableObject {
    public override class var typeName: String { "ActionTestSummaryGroup" }
    
    public let duration: RSDouble?
    public let subtests: RSArray<RSActionTestMetadata>?
    
    public init(
        identifier: RSString,
        name: RSString,
        duration: RSDouble?,
        subtests: RSArray<RSActionTestMetadata>?
    ) {
        self.duration = duration
        self.subtests = subtests
        
        super.init(identifier: identifier, name: name)
    }
    
    enum CodingKeys: CodingKey {
        case duration
        case subtests
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        duration = try container.decodeIfPresent(RSDouble.self, forKey: .duration)
        subtests = try container.decodeIfPresent(RSArray<RSActionTestMetadata>.self, forKey: .subtests)
        
        try super.init(from: decoder)
    }
}

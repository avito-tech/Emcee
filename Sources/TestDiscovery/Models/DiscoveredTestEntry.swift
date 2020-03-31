import Foundation

public struct DiscoveredTestEntry: Codable, CustomStringConvertible, Equatable {
    public let className: String
    public let path: String
    public let testMethods: [String]
    public let caseId: UInt?
    public let tags: [String]

    public init(className: String, path: String, testMethods: [String], caseId: UInt?, tags: [String]) {
        self.className = className
        self.path = path
        self.testMethods = testMethods
        self.caseId = caseId
        self.tags = tags
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        className = try container.decode(String.self, forKey: .className)
        path = try container.decode(String.self, forKey: .path)
        testMethods = try container.decode([String].self, forKey: .testMethods)
        caseId = try container.decodeIfPresent(UInt.self, forKey: .caseId)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(className, forKey: .className)
        try container.encode(path, forKey: .path)
        try container.encode(testMethods, forKey: .testMethods)
        if let caseId = caseId {
            try container.encode(caseId, forKey: .caseId)
        }
        if !tags.isEmpty {
            try container.encode(tags, forKey: .tags)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case className
        case path
        case testMethods
        case caseId
        case tags
    }
    
    public var description: String {
        var identifyingComponents = [String]()
        if let caseId = caseId {
            identifyingComponents.append("id \(caseId)")
        }
        identifyingComponents.append(className)
        
        let testMethodsJoined = testMethods.joined(separator: "|")
        let identifyingComponentsJoined = identifyingComponents.joined(separator: ",")
        
        var topLevelComponents = [
            identifyingComponentsJoined,
            "[\(testMethodsJoined)]"
        ]
        
        if !tags.isEmpty {
            let tagsJoined = tags.joined(separator: "|")
            topLevelComponents.append("tags [\(tagsJoined)]")
        }
        
        let topLevelComponentsJoined = topLevelComponents.joined(separator: " / ")
        
        return "(\(DiscoveredTestEntry.self): \(topLevelComponentsJoined)"
    }
}

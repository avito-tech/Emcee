import Foundation

public struct RuntimeTestEntry: Codable, CustomStringConvertible {
    public let className: String
    public let path: String
    public let testMethods: [String]
    public let caseId: UInt?
    
    public var description: String {
        var identifyingComponents = [String]()
        if let caseId = caseId {
            identifyingComponents.append("id \(caseId)")
        }
        identifyingComponents.append(className)
        
        let testMethodsJoined = testMethods.joined(separator: "|")
        let identifyingComponentsJoined = identifyingComponents.joined(separator: ",")
        
        return "(\(RuntimeTestEntry.self): \(identifyingComponentsJoined) / [\(testMethodsJoined)])"
    }
}

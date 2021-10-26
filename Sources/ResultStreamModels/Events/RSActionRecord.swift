import Foundation

public struct RSActionRecord: Codable, Equatable, RSTypedValue {
    public static var typeName: String { "ActionRecord" }
    
    public let actionResult: RSActionResult
//    public let buildResult: RSActionResult
    public let startedTime: RSDate
    public let endedTime: RSDate
    public let schemeTaskName: RSString       // BuildAndAction
    public let schemeCommandName: RSString    // Test
//    public let runDestination: RSActionRunDestinationRecord

    public init(
        actionResult: RSActionResult,
        startedTime: RSDate,
        endedTime: RSDate,
        schemeTaskName: RSString,
        schemeCommandName: RSString
    ) {
        self.actionResult = actionResult
        self.startedTime = startedTime
        self.endedTime = endedTime
        self.schemeTaskName = schemeTaskName
        self.schemeCommandName = schemeCommandName
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        actionResult = try container.decode(RSActionResult.self, forKey: .actionResult)
        startedTime = try container.decode(RSDate.self, forKey: .startedTime)
        endedTime = try container.decode(RSDate.self, forKey: .endedTime)
        schemeTaskName = try container.decode(RSString.self, forKey: .schemeTaskName)
        schemeCommandName = try container.decode(RSString.self, forKey: .schemeCommandName)
    }
}

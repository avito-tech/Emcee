import Foundation

public final class SimulatorInfo: Codable, Hashable, CustomStringConvertible {
    public let simulatorUuid: UUID?
    public let simulatorSetPath: String
    public let testDestination: TestDestination

    public init(simulatorUuid: UUID?, simulatorSetPath: String, testDestination: TestDestination) {
        self.simulatorUuid = simulatorUuid
        self.simulatorSetPath = simulatorSetPath
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "Simulator \(simulatorUuid?.uuidString ?? "null uuid") \(testDestination) \(simulatorSetPath)"
    }
    
    public static func == (left: SimulatorInfo, right: SimulatorInfo) -> Bool {
        return left.simulatorUuid == right.simulatorUuid
            && left.simulatorSetPath == right.simulatorSetPath
            && left.testDestination == right.testDestination
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(simulatorUuid)
        hasher.combine(simulatorSetPath)
        hasher.combine(testDestination)
    }
}

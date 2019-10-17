import Foundation

public final class SimulatorInfo: Codable, Hashable, CustomStringConvertible {
    
    /// This is simulator's id. Usually this is UUID-like string. `String` type is used to preserve case sensivity information.
    public let simulatorUuid: String?
    public let simulatorSetPath: String
    public let testDestination: TestDestination

    public init(simulatorUuid: String?, simulatorSetPath: String, testDestination: TestDestination) {
        self.simulatorUuid = simulatorUuid
        self.simulatorSetPath = simulatorSetPath
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "Simulator \(simulatorUuid ?? "null uuid") \(testDestination) \(simulatorSetPath)"
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

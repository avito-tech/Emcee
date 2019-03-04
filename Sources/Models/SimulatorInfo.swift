import Foundation

public final class SimulatorInfo: Codable, Hashable {
    public let simulatorUuid: UUID?
    public let simulatorSetPath: String

    public init(simulatorUuid: UUID?, simulatorSetPath: String) {
        self.simulatorUuid = simulatorUuid
        self.simulatorSetPath = simulatorSetPath
    }
    
    public static func == (left: SimulatorInfo, right: SimulatorInfo) -> Bool {
        return left.simulatorUuid == right.simulatorUuid
            && left.simulatorSetPath == right.simulatorSetPath
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(simulatorUuid)
        hasher.combine(simulatorSetPath)
    }
}

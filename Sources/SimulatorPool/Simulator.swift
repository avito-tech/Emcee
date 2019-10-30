import Foundation
import Extensions
import Models
import PathLib

public class Simulator: Hashable, CustomStringConvertible {
    public let testDestination: TestDestination
    public let udid: UDID
    public let path: AbsolutePath

    public init(testDestination: TestDestination, udid: UDID, path: AbsolutePath) {
        self.testDestination = testDestination
        self.udid = udid
        self.path = path
    }
    
    public var identifier: String {
        return "simulator_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.runtime.removingWhitespaces())"
    }
    
    public var description: String {
        return "Simulator \(testDestination.deviceType) \(testDestination.runtime) at \(path)"
    }

    public static func == (left: Simulator, right: Simulator) -> Bool {
        return left.testDestination == right.testDestination
            && left.udid == right.udid
            && left.path == right.path
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testDestination)
        hasher.combine(udid)
        hasher.combine(path)
    }
}

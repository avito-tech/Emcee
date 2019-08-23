import Foundation
import Extensions
import Models
import PathLib

/// Represents a single simulator wrapped into a folder which contains a simulator set with it.
/// Simulator set is a private to simctl structure that desribes a set of simulators.
public class Simulator: Hashable, CustomStringConvertible {
    public let index: UInt
    public let testDestination: TestDestination
    public let workingDirectory: AbsolutePath
    
    public var identifier: String {
        return "simulator_\(index)_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.runtime.removingWhitespaces())"
    }
    
    public var description: String {
        return "Simulator \(index): \(testDestination.deviceType) \(testDestination.runtime) at: \(workingDirectory)"
    }
    
    public var simulatorInfo: SimulatorInfo {
        return SimulatorInfo(
            simulatorUuid: uuid,
            simulatorSetPath: simulatorSetContainerPath.pathString,
            testDestination: testDestination
        )
    }
    
    /// A path to simctl's simulator set structure. If created, simulator will be placed inside this folder.
    public var simulatorSetContainerPath: AbsolutePath {
        return workingDirectory.appending(component: "sim")
    }
    
    /// Simulator's UUID/UDID if it has been created. Will return nil if it hasn't been created yet.
    /// Currently there is an assumption that simulator set contains only a single simulator.
    public var uuid: UUID? {
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: simulatorSetContainerPath.pathString)) ?? []
        return contents.compactMap({ UUID(uuidString: $0) }).first
    }
 
    init(index: UInt, testDestination: TestDestination, workingDirectory: AbsolutePath) {
        self.index = index
        self.testDestination = testDestination
        self.workingDirectory = workingDirectory
    }
    
    public static func == (left: Simulator, right: Simulator) -> Bool {
        return left.index == right.index
            && left.workingDirectory == right.workingDirectory
            && left.testDestination == right.testDestination
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(testDestination)
        hasher.combine(workingDirectory)
    }
}

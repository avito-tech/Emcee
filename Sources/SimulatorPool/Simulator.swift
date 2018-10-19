import Basic
import Foundation
import Extensions
import Models

public class Simulator: Hashable, CustomStringConvertible {
    public let index: UInt
    public let testDestination: TestDestination
    public let workingDirectory: AbsolutePath
    
    public var identifier: String {
        return "simulator_\(index)_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.iOSVersion.removingWhitespaces())"
    }
    
    public var description: String {
        return "Simulator \(index): \(testDestination.deviceType) \(testDestination.iOSVersion) at: \(workingDirectory)"
    }
    
    var fbxctestContainerPath: AbsolutePath {
        return workingDirectory.appending(component: "sim")
    }
 
    init(index: UInt, testDestination: TestDestination, workingDirectory: AbsolutePath) {
        self.index = index
        self.testDestination = testDestination
        self.workingDirectory = workingDirectory
    }
    
    public static func == (l: Simulator, r: Simulator) -> Bool {
        return l.index == r.index &&
            l.workingDirectory == r.workingDirectory &&
            l.testDestination == r.testDestination
    }
    
    public var hashValue: Int {
        return index.hashValue ^ testDestination.hashValue ^ workingDirectory.hashValue
    }
}

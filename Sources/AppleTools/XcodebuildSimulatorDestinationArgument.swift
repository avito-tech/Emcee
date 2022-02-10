import CommonTestModels
import Foundation
import ProcessController

public class XcodebuildSimulatorDestinationArgument: SubprocessArgument, CustomStringConvertible {
    private let xcodeDestinationString: String

    public init(destinationId: UDID) {
        self.xcodeDestinationString = "platform=iOS Simulator,id=\(destinationId.value)"
    }

    public func stringValue() throws -> String {
        return xcodeDestinationString
    }
    
    public var description: String {
        return xcodeDestinationString
    }
}

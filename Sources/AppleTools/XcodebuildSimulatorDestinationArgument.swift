import Foundation
import Models
import ProcessController

public class XcodebuildSimulatorDestinationArgument: SubprocessArgument {
    private let destinationId: UDID

    public init(destinationId: UDID) {
        self.destinationId = destinationId
    }

    public func stringValue() throws -> String {
        return "platform=iOS Simulator,id=\(destinationId.value)"
    }
}

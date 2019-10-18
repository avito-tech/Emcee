import Foundation
import Models
import ProcessController

public class XcodebuildSimulatorDestinationArgument: SubprocessArgument {
    private let simulatorInfo: SimulatorInfo
    private let testType: TestType
    
    public enum SimulatorDestinationError: Error, CustomStringConvertible {
        case noSimulatorUuid(SimulatorInfo)
        
        public var description: String {
            switch self {
            case .noSimulatorUuid(let simulatorInfo):
                return "Cannot determine UUID of simulator \(simulatorInfo)"
            }
        }
    }

    public init(
        simulatorInfo: SimulatorInfo,
        testType: TestType
    ) {
        self.simulatorInfo = simulatorInfo
        self.testType = testType
    }

    public func stringValue() throws -> String {
        if testType == .logicTest {
            let testDestination = simulatorInfo.testDestination
            return "platform=iOS Simulator,name=\(testDestination.deviceType),OS=\(testDestination.runtime)"
        }

        guard let simulatorUuid = simulatorInfo.simulatorUuid else {
            throw SimulatorDestinationError.noSimulatorUuid(simulatorInfo)
        }
        return "platform=iOS Simulator,id=\(simulatorUuid)"
    }
}

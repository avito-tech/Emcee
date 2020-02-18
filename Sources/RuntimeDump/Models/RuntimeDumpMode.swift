import Foundation
import Models
import SimulatorPoolModels

public enum RuntimeDumpMode: Hashable {
    case logicTest(SimulatorControlTool)
    case appTest(RuntimeDumpApplicationTestSupport)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .logicTest(let data):
            hasher.combine("logicTest")
            hasher.combine(data)
        case .appTest(let data):
            hasher.combine("appTest")
            hasher.combine(data)
        }
    }
}

import Foundation
import Models
import SimulatorPoolModels

public enum TestDiscoveryMode: Hashable {
    case runtimeLogicTest(SimulatorControlTool)
    case runtimeAppTest(RuntimeDumpApplicationTestSupport)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .runtimeLogicTest(let data):
            hasher.combine("runtimeLogicTest")
            hasher.combine(data)
        case .runtimeAppTest(let data):
            hasher.combine("runtimeAppTest")
            hasher.combine(data)
        }
    }
}

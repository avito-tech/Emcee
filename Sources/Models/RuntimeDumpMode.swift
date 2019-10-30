import Foundation

public enum RuntimeDumpMode: Equatable {
    case logicTest(SimulatorControlTool)
    case appTest(RuntimeDumpApplicationTestSupport)
}

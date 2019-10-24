import Foundation

public enum RuntimeDumpMode: Equatable {
    case logicTest
    case appTest(RuntimeDumpApplicationTestSupport)
}

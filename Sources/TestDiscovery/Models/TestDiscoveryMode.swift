import BuildArtifacts
import Foundation
import Models
import SimulatorPoolModels

public enum TestDiscoveryMode: Hashable {
    case parseFunctionSymbols
    case runtimeExecutableLaunch(AppBundleLocation)
    case runtimeLogicTest(SimulatorControlTool)
    case runtimeAppTest(RuntimeDumpApplicationTestSupport)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .parseFunctionSymbols:
            hasher.combine("parseFunctionSymbols")
        case .runtimeExecutableLaunch(let data):
            hasher.combine("runtimeExecutableLaunch")
            hasher.combine(data)
        case .runtimeLogicTest(let data):
            hasher.combine("runtimeLogicTest")
            hasher.combine(data)
        case .runtimeAppTest(let data):
            hasher.combine("runtimeAppTest")
            hasher.combine(data)
        }
    }
}

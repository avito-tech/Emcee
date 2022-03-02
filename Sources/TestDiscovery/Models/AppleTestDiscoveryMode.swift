import BuildArtifacts
import Foundation
import SimulatorPoolModels

public enum AppleTestDiscoveryMode: Hashable {
    case parseFunctionSymbols
    case runtimeExecutableLaunch(AppBundleLocation)
    case runtimeLogicTest
    case runtimeAppTest(RuntimeDumpApplicationTestSupport)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .parseFunctionSymbols:
            hasher.combine("parseFunctionSymbols")
        case .runtimeExecutableLaunch(let data):
            hasher.combine("runtimeExecutableLaunch")
            hasher.combine(data)
        case .runtimeLogicTest:
            hasher.combine("runtimeLogicTest")
        case .runtimeAppTest(let data):
            hasher.combine("runtimeAppTest")
            hasher.combine(data)
        }
    }
}

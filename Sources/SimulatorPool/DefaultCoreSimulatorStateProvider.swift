import Foundation
import SimulatorPoolModels
import PlistLib

public final class DefaultCoreSimulatorStateProvider: CoreSimulatorStateProvider {
    public init() {}
    
    public func coreSimulatorState(simulator: Simulator) throws -> CoreSimulatorState? {
        guard let data = try? Data(contentsOf: simulator.devicePlistPath.fileUrl) else {
            return nil
        }
        let plist = try Plist.create(fromData: data)
        return CoreSimulatorState(
            rawValue: Int(try plist.root.plistEntry.entry(forKey: "state").numberValue())
        )
    }
}

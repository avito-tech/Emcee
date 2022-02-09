import Foundation
import SimulatorPoolModels

public enum SimRuntimeFixture {
    public static func fixture(_ fqid: String = "fake.simRuntime") -> SimRuntime {
        return SimRuntime(fullyQualifiedId: fqid)
    }
    
    public static func iOS(_ version: String = "12.0") -> SimRuntime {
        return SimRuntime(
            fullyQualifiedId: "com.apple.CoreSimulator.SimRuntime.iOS-"
            + version.replacingOccurrences(of: ".", with: "-")
        )
    }
}

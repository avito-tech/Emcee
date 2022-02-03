import Foundation
import SimulatorPoolModels
import TestDestination

public enum TestDestinationFixtures {
    public static let iOSTestDestination = TestDestination.iOSSimulator(
        deviceType: "device",
        version: "12.0"
    )
}

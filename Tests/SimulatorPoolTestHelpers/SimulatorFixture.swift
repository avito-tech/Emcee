import Foundation
import Models
import ModelsTestHelpers
import PathLib
import SimulatorPool

public final class SimulatorFixture {
    public static func simulator(
        testDestination: TestDestination = TestDestinationFixtures.testDestination,
        udid: UDID = UDID(value: "fixture_udid"),
        path: AbsolutePath = AbsolutePath(NSTemporaryDirectory())
    ) -> Simulator {
        return Simulator(
            testDestination: testDestination,
            udid: udid,
            path: path
        )
    }
}

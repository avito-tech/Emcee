import Foundation
import PathLib
import SimulatorPoolModels
import TestDestination
import TestDestinationTestHelpers

public final class SimulatorFixture {
    public static func simulator(
        testDestination: TestDestination = TestDestinationFixtures.iOSTestDestination,
        udid: UDID = UDID(value: "fixture_udid"),
        path: AbsolutePath = AbsolutePath(NSTemporaryDirectory()).appending("emcee_fixtures", "fixture_udid")
    ) -> Simulator {
        return Simulator(
            testDestination: testDestination,
            udid: udid,
            path: path
        )
    }
}

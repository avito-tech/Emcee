import Foundation
import PathLib
import SimulatorPoolModels

public final class SimulatorFixture {
    public static func simulator(
        testDestination: TestDestination = TestDestinationFixtures.testDestination,
        udid: UDID = UDID(value: "fixture_udid"),
        path: AbsolutePath = AbsolutePath(NSTemporaryDirectory()).appending(components: ["emcee_fixtures", "fixture_udid"])
    ) -> Simulator {
        return Simulator(
            testDestination: testDestination,
            udid: udid,
            path: path
        )
    }
}

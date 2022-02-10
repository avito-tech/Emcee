import CommonTestModels
import Foundation
import PathLib
import SimulatorPoolModels

public final class SimulatorFixture {
    public static func simulator(
        simDeviceType: SimDeviceType = SimDeviceTypeFixture.fixture(),
        simRuntime: SimRuntime = SimRuntimeFixture.fixture(),
        udid: UDID = UDID(value: "fixture_udid"),
        path: AbsolutePath
    ) -> Simulator {
        return Simulator(
            simDeviceType: simDeviceType,
            simRuntime: simRuntime,
            udid: udid,
            path: path
        )
    }
}

import Foundation
import Models
import SimulatorPoolModels

public final class SimulatorControlToolFixtures {
    public static let fakeFbsimctlUrl = URL(string: "http://example.com/fbsimctl.zip#fbsimctl")!
    
    public static let fakeFbsimctlTool = SimulatorControlTool.fbsimctl(
        FbsimctlLocation(
            .remoteUrl(fakeFbsimctlUrl)
        )
    )
}

import Foundation
import Models

public final class SimulatorControlToolFixtures {
    public static let fakeFbsimctlUrl = URL(string: "http://example.com/fbsimctl.zip#fbsimctl")!
    
    public static let fakeFbsimctlTool = SimulatorControlTool.fbsimctl(
        FbsimctlLocation(
            .remoteUrl(fakeFbsimctlUrl)
        )
    )
}

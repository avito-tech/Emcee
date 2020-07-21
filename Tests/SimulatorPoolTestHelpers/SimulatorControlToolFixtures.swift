import Foundation
import SimulatorPoolModels

public final class SimulatorControlToolFixtures {
    public static let fakeFbsimctlUrl = URL(string: "http://example.com/fbsimctl.zip#fbsimctl")!
    
    public static let fakeFbsimctlTool = SimulatorControlTool(
        location: .insideEmceeTempFolder,
        tool: .fbsimctl(
            FbsimctlLocation(
                .remoteUrl(fakeFbsimctlUrl)
            )
        )
    )
}

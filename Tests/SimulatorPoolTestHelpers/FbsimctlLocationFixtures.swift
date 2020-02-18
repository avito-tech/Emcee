import Foundation
import Models
import SimulatorPoolModels

public final class FbsimcrlLocationFixtures {
    public static let fakeFbsimctlUrl = URL(string: "http://example.com/fbsimctl.zip#fbsimctl")!
    public static let fakeFbsimctlLocation = FbsimctlLocation(.remoteUrl(fakeFbsimctlUrl))
}

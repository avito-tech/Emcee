import Foundation
import Models
import RunnerModels

public final class FbxctestLocationFixtures {
    public static let fakeFbxctestUrl = URL(string: "http://example.com/fbxctest.zip#fbxctest")!
    public static let fakeFbxctestLocation = FbxctestLocation(.remoteUrl(fakeFbxctestUrl))
}

import Foundation
import Models

public final class TestRunnerToolFixtures {
    public static let fakeFbxctestUrl = URL(string: "http://example.com/fbxctest.zip#fbxctest")!
    
    public static let fakeFbxctestTool = TestRunnerTool.fbxctest(
        FbxctestLocation(
            .remoteUrl(fakeFbxctestUrl)
        )
    )
}

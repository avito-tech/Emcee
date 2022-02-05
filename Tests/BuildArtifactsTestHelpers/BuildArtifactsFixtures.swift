import BuildArtifacts
import Foundation
import ResourceLocation
import TestDiscovery

public final class BuildArtifactsFixtures {
    public static func fakeEmptyBuildArtifacts(
        testBundlePath: String = "/bundle",
        testDiscoveryMode: XcTestBundleTestDiscoveryMode = .parseFunctionSymbols
    ) -> AppleBuildArtifacts {
        .iosLogicTests(
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath(testBundlePath)),
                testDiscoveryMode: testDiscoveryMode
            )
        )
    }
}

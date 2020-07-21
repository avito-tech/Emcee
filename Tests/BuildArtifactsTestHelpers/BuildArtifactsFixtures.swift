import BuildArtifacts
import Foundation

public final class BuildArtifactsFixtures {
    public static func fakeEmptyBuildArtifacts(
        appBundleLocation: String? = "",
        testDiscoveryMode: XcTestBundleTestDiscoveryMode = .runtimeLogicTest
    ) -> BuildArtifacts {
        let appBundle = appBundleLocation != nil ? AppBundleLocation(.localFilePath(appBundleLocation!)) : nil
        return BuildArtifacts(
            appBundle: appBundle,
            runner: RunnerAppLocation(.localFilePath("")),
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath("")),
                testDiscoveryMode: testDiscoveryMode
            ),
            additionalApplicationBundles: []
        )
    }
    
    public static func withLocalPaths(
        appBundle: String?,
        runner: String?,
        xcTestBundle: String,
        additionalApplicationBundles: [String],
        testDiscoveryMode: XcTestBundleTestDiscoveryMode = .runtimeLogicTest
    ) -> BuildArtifacts {
        return BuildArtifacts(
            appBundle: appBundle != nil ? AppBundleLocation(.localFilePath(appBundle!)) : nil,
            runner: runner != nil ? RunnerAppLocation(.localFilePath(runner!)) : nil,
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath(xcTestBundle)),
                testDiscoveryMode: testDiscoveryMode
            ),
            additionalApplicationBundles: additionalApplicationBundles.map { AdditionalAppBundleLocation(.localFilePath($0)) }
        )
    }
}

import BuildArtifacts
import Foundation
import ResourceLocation

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
            additionalApplicationBundles: [],
            hostsTokens: [:]
        )
    }
    
    public static func withLocalPaths(
        appBundle: String?,
        runner: String?,
        xcTestBundle: String,
        additionalApplicationBundles: [String],
        testDiscoveryMode: XcTestBundleTestDiscoveryMode = .runtimeLogicTest,
        hostsTokens: [String: String] = [:]
    ) -> BuildArtifacts {
        return BuildArtifacts(
            appBundle: appBundle != nil ? AppBundleLocation(.localFilePath(appBundle!)) : nil,
            runner: runner != nil ? RunnerAppLocation(.localFilePath(runner!)) : nil,
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath(xcTestBundle)),
                testDiscoveryMode: testDiscoveryMode
            ),
            additionalApplicationBundles: additionalApplicationBundles.map { AdditionalAppBundleLocation(.localFilePath($0)) },
            hostsTokens: hostsTokens
        )
    }
    
    public static func with(
        appBundle: ResourceLocation? = nil,
        runner: ResourceLocation? = nil,
        xcTestBundle: XcTestBundle,
        additionalApplicationBundles: [ResourceLocation] = [],
        hostsTokens: [String: String] = [:]
    ) -> BuildArtifacts {
        BuildArtifacts(
            appBundle: AppBundleLocation(appBundle),
            runner: RunnerAppLocation(runner),
            xcTestBundle: xcTestBundle,
            additionalApplicationBundles: additionalApplicationBundles.map { AdditionalAppBundleLocation($0) },
            hostsTokens: ["host": "token"]
        )
    }
}

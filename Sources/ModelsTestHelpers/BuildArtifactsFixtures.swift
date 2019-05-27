import Foundation
import Models

public final class BuildArtifactsFixtures {
    public static func fakeEmptyBuildArtifacts(
        appBundleLocation: String? = ""
    ) -> BuildArtifacts {
        let appBundle = appBundleLocation != nil ? AppBundleLocation(.localFilePath(appBundleLocation!)) : nil
        return BuildArtifacts(
            appBundle: appBundle,
            runner: RunnerAppLocation(.localFilePath("")),
            xcTestBundle: TestBundleLocation(.localFilePath("")),
            additionalApplicationBundles: [])
    }
    
    public static func withLocalPaths(
        appBundle: String?,
        runner: String?,
        xcTestBundle: String,
        additionalApplicationBundles: [String])
        -> BuildArtifacts
    {
        return BuildArtifacts(
            appBundle: appBundle != nil ? AppBundleLocation(.localFilePath(appBundle!)) : nil,
            runner: runner != nil ? RunnerAppLocation(.localFilePath(runner!)) : nil,
            xcTestBundle: TestBundleLocation(.localFilePath(xcTestBundle)),
            additionalApplicationBundles: additionalApplicationBundles.map { AdditionalAppBundleLocation(.localFilePath($0)) })
    }
}

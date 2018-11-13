import Foundation
import Models

public final class BuildArtifactsFixtures {
    public static func fakeEmptyBuildArtifacts() -> BuildArtifacts {
        return BuildArtifacts(
            appBundle: AppBundleLocation(.localFilePath("")),
            runner: RunnerAppLocation(.localFilePath("")),
            xcTestBundle: TestBundleLocation(.localFilePath("")),
            additionalApplicationBundles: [])
    }
    
    public static func withLocalPaths(
        appBundle: String,
        runner: String,
        xcTestBundle: String,
        additionalApplicationBundles: [String])
        -> BuildArtifacts
    {
        return BuildArtifacts(
            appBundle: AppBundleLocation(.localFilePath(appBundle)),
            runner: RunnerAppLocation(.localFilePath(runner)),
            xcTestBundle: TestBundleLocation(.localFilePath(xcTestBundle)),
            additionalApplicationBundles: additionalApplicationBundles.map { AdditionalAppBundleLocation(.localFilePath($0)) })
    }
}

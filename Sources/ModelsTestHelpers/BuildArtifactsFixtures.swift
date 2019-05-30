import Foundation
import Models

public final class BuildArtifactsFixtures {
    public static func fakeEmptyBuildArtifacts(
        appBundleLocation: String? = "",
        runtimeDumpKind: RuntimeDumpKind = .logicTest
    ) -> BuildArtifacts {
        let appBundle = appBundleLocation != nil ? AppBundleLocation(.localFilePath(appBundleLocation!)) : nil
        return BuildArtifacts(
            appBundle: appBundle,
            runner: RunnerAppLocation(.localFilePath("")),
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath("")),
                runtimeDumpKind: runtimeDumpKind
            ),
            additionalApplicationBundles: []
        )
    }
    
    public static func withLocalPaths(
        appBundle: String?,
        runner: String?,
        xcTestBundle: String,
        additionalApplicationBundles: [String],
        runtimeDumpKind: RuntimeDumpKind = .logicTest
    ) -> BuildArtifacts {
        return BuildArtifacts(
            appBundle: appBundle != nil ? AppBundleLocation(.localFilePath(appBundle!)) : nil,
            runner: runner != nil ? RunnerAppLocation(.localFilePath(runner!)) : nil,
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath(xcTestBundle)),
                runtimeDumpKind: runtimeDumpKind
            ),
            additionalApplicationBundles: additionalApplicationBundles.map { AdditionalAppBundleLocation(.localFilePath($0)) }
        )
    }
}

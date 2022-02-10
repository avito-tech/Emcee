import BuildArtifacts
import Foundation
import ResourceLocation
import TestDiscovery

public final class AppleBuildArtifactsFixture {
    public var result: AppleBuildArtifacts
    
    public init(
        result: AppleBuildArtifacts = .iosLogicTests(
            xcTestBundle: XcTestBundleFixture().xcTestBundle()
        )
    ) {
        self.result = result
    }
    
    public func logicTests(
        xcTestBundle: XcTestBundle = XcTestBundleFixture().xcTestBundle()
    ) -> Self {
        self.result = .iosLogicTests(xcTestBundle: xcTestBundle)
        return self
    }
    
    public func applicationTests(
        xcTestBundle: XcTestBundle = XcTestBundleFixture().xcTestBundle(),
        appBundle: AppBundleLocation = AppBundleLocation(.localFilePath("/app.app"))
    ) -> Self {
        self.result = .iosApplicationTests(
            xcTestBundle: xcTestBundle,
            appBundle: appBundle
        )
        return self
    }
    
    public func uiTests(
        xcTestBundle: XcTestBundle = XcTestBundleFixture().xcTestBundle(),
        appBundle: AppBundleLocation = AppBundleLocation(.localFilePath("/app.app")),
        runner: RunnerAppLocation = RunnerAppLocation(.localFilePath("/runner.app")),
        additionalApplicationBundles: [AdditionalAppBundleLocation] = []
    ) -> Self {
        self.result = .iosUiTests(
            xcTestBundle: xcTestBundle,
            appBundle: appBundle,
            runner: runner,
            additionalApplicationBundles: additionalApplicationBundles
        )
        return self
    }
 
    public func appleBuildArtifacts() -> AppleBuildArtifacts {
        result
    }
}

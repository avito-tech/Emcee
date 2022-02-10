import BuildArtifacts
import Foundation

public final class AndroidBuildArtifactsFixture {
    public var result: AndroidBuildArtifacts
    
    public init(
        result: AndroidBuildArtifacts = .applicationTests(
            appApk: ApkLocation(.localFilePath("app.apk")),
            testApk: ApkLocation(.localFilePath("tests.apk"))
        )
    ) {
        self.result = result
    }
    
    public func with(
        appApk: ApkLocation = ApkLocation(.localFilePath("app.apk")),
        testApk: ApkLocation = ApkLocation(.localFilePath("tests.apk"))
    ) -> Self {
        result = .applicationTests(appApk: appApk, testApk: testApk)
        return self
    }
    
    public func androidBuildArtifacts() -> AndroidBuildArtifacts {
        result
    }
}

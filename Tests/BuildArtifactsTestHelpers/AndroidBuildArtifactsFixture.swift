import BuildArtifacts
import Foundation

public final class AndroidBuildArtifactsFixture {
    public var result: AndroidBuildArtifacts
    
    public init(
        result: AndroidBuildArtifacts = AndroidBuildArtifacts(
            appApk: ApkDescription(
                location: ApkLocation(.localFilePath("app.apk")),
                package: "ru.avito.app.package"
            ),
            testApk: ApkDescription(
                location: ApkLocation(.localFilePath("tests.apk")),
                package: "ru.avito.tests.package"
            ),
            runnerClass: "ru.avito.runnerClass"
        )
    ) {
        self.result = result
    }
    
    public func with(
        appApk: ApkDescription = ApkDescription(
            location: ApkLocation(.localFilePath("app.apk")),
            package: "ru.avito.app.package"
        ),
        testApk: ApkDescription = ApkDescription(
            location: ApkLocation(.localFilePath("tests.apk")),
            package: "ru.avito.tests.package"
        ),
        runnerClass: String = "ru.avito.runnerClass"
    ) -> Self {
        result = AndroidBuildArtifacts(
            appApk: appApk,
            testApk: testApk,
            runnerClass: runnerClass
        )
        return self
    }
    
    public func androidBuildArtifacts() -> AndroidBuildArtifacts {
        result
    }
}

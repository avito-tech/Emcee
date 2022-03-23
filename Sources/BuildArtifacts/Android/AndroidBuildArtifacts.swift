import Foundation

public struct AndroidBuildArtifacts: Codable, Hashable, CustomStringConvertible {
    public let appApk: ApkDescription
    public let testApk: ApkDescription
    public let runnerClass: String
    
    public init(
        appApk: ApkDescription,
        testApk: ApkDescription,
        runnerClass: String
    ) {
        self.appApk = appApk
        self.testApk = testApk
        self.runnerClass = runnerClass
    }
    
    public var description: String {
        "<app: \(appApk) tests: \(testApk) runnerClass: \(runnerClass)>"
    }
}

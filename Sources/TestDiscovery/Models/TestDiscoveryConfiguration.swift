import Foundation
import MetricsExtensions
import TestArgFile

public protocol TestDiscoveryConfiguration {
    var analyticsConfiguration: AnalyticsConfiguration { get }
    var remoteCache: RuntimeDumpRemoteCache { get }
    var testsToValidate: [TestToRun] { get }
}

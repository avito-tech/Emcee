import Foundation

public struct WorkerConfiguration: Codable, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let pluginUrls: [URL]
    public let reportAliveInterval: TimeInterval
    public let requestSignature: RequestSignature
    public let testRunExecutionBehavior: TestRunExecutionBehavior

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        pluginUrls: [URL],
        reportAliveInterval: TimeInterval,
        requestSignature: RequestSignature,
        testRunExecutionBehavior: TestRunExecutionBehavior
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.pluginUrls = pluginUrls
        self.reportAliveInterval = reportAliveInterval
        self.requestSignature = requestSignature
        self.testRunExecutionBehavior = testRunExecutionBehavior
    }
}

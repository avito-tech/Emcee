import Foundation

public struct WorkerConfiguration: Codable, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let reportAliveInterval: TimeInterval
    public let requestSignature: PayloadSignature
    public let testRunExecutionBehavior: TestRunExecutionBehavior

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        reportAliveInterval: TimeInterval,
        requestSignature: PayloadSignature,
        testRunExecutionBehavior: TestRunExecutionBehavior
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.reportAliveInterval = reportAliveInterval
        self.requestSignature = requestSignature
        self.testRunExecutionBehavior = testRunExecutionBehavior
    }
}

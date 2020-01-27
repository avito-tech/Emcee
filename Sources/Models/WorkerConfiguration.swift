import Foundation

public struct WorkerConfiguration: Codable, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let reportAliveInterval: TimeInterval
    public let payloadSignature: PayloadSignature
    public let testRunExecutionBehavior: TestRunExecutionBehavior

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        reportAliveInterval: TimeInterval,
        payloadSignature: PayloadSignature,
        testRunExecutionBehavior: TestRunExecutionBehavior
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.reportAliveInterval = reportAliveInterval
        self.payloadSignature = payloadSignature
        self.testRunExecutionBehavior = testRunExecutionBehavior
    }
}

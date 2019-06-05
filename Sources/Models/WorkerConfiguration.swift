import Foundation

public struct WorkerConfiguration: Codable, Equatable {
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration

    public let pluginUrls: [URL]

    /// An interval the workers should use to report their aliveness to the queue server.
    public let reportAliveInterval: TimeInterval

    /// Request signature that should be used to sign requests to the queue.
    public let requestSignature: RequestSignature

    public init(
        testRunExecutionBehavior: TestRunExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        pluginUrls: [URL],
        reportAliveInterval: TimeInterval,
        requestSignature: RequestSignature
        )
    {
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.pluginUrls = pluginUrls
        self.reportAliveInterval = reportAliveInterval
        self.requestSignature = requestSignature
    }
}

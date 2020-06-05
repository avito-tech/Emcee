import Foundation
import ProcessController
import Runner

public final class FakeTestRunnerInvocation: TestRunnerInvocation {
    public init() {}

    public func startExecutingTests() -> TestRunnerRunningInvocation {
        FakeTestRunnerRunningInvocation()
    }
}

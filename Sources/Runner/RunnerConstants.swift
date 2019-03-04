import Foundation

public enum RunnerConstants: String {
    /// Test failure reason that will be given back if test has actually failed to run after all attempts to revive.
    case testDidNotRun = "Test did not run at all after all attempts to run it again"
}

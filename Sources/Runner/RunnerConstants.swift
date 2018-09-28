import Foundation

public enum RunnerConstants: String {
    /// Test failure reason that will be given back if test has actually failed to run after all attempts to revive.
    case testDidNotRun = "Test did not run at all after all attempts to run it again"
    
    /// A working directory that tests may use to drop their artifacts.
    /// Runner plugins may then pick these artifacts after Runner finishes executing the tests.
    case envTestsWorkingDirectory = "EMCEE_TESTS_WORKING_DIRECTORY"
}

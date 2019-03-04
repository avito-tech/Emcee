import Foundation

/// A working directory path that tests may use to drop their artifacts.
/// Runner plugins may then pick these artifacts after Emcee finishes executing the tests.
public final class TestsWorkingDirectorySupport {
    public static let envTestsWorkingDirectory = "EMCEE_TESTS_WORKING_DIRECTORY"
}

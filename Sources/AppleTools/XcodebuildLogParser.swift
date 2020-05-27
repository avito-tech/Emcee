import Runner

public protocol XcodebuildLogParser {
    func parse(
        string: String,
        testRunnerStream: TestRunnerStream
    ) throws
}

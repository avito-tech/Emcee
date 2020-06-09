import Foundation

extension Subprocess {
    func byRedefiningOutput(
        redefiner: (StandardStreamsCaptureConfig) throws -> StandardStreamsCaptureConfig
    ) rethrows -> Subprocess {
        Subprocess(
            arguments: arguments,
            environment: environment,
            automaticManagement: automaticManagement,
            standardStreamsCaptureConfig: try redefiner(standardStreamsCaptureConfig),
            workingDirectory: workingDirectory
        )
    }
}

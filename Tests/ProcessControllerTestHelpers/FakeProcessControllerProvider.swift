@testable import ProcessController
import Foundation
import TemporaryStuff

public final class FakeProcessControllerProvider: ProcessControllerProvider {
    public var tempFolder: TemporaryFolder
    public var creator: (Subprocess) throws -> (ProcessController)
    
    public init(
        tempFolder: TemporaryFolder,
        creator: @escaping (Subprocess) throws -> ProcessController = { FakeProcessController(subprocess: $0)}
    ) {
        self.tempFolder = tempFolder
        self.creator = creator
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        let uuid = UUID()
        return try creator(
            subprocess.byRedefiningOutput(
                redefiner: {
                    $0.byRedefiningIfNotSet(
                        stdoutOutputPath: tempFolder.absolutePath.appending(component: "\(uuid)_stdout.log"),
                        stderrOutputPath: tempFolder.absolutePath.appending(component: "\(uuid)_stderr.log")
                    )
                }
            )
        )
    }
}

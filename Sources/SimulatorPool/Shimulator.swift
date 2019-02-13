import Basic
import Foundation
import Models

public final class Shimulator: Simulator {
    public static func shimulator(testDestination: TestDestination, workingDirectory: AbsolutePath) -> Shimulator {
        return Shimulator(
            index: 0,
            testDestination: testDestination,
            workingDirectory: workingDirectory
        )
    }
}

import Foundation
import Models

public protocol EventStream {
    
    /// Called when a `TestingResult` has been obtained for a corresponding `Bucket`.
    func didObtain(testingResult: TestingResult)
    
    /// Called when listener should tear down
    func tearDown()
}

import Foundation
import ProcessController
import ProcessControllerTestHelpers
import UpdatingFileReader
import XCTest

final class UpdatingFileReaderHandleTests: XCTestCase {
    lazy var processController = FakeProcessController(subprocess: Subprocess(arguments: []))
    
    func test() {
        processController.start()
        
        let handle = ProcessUpdatingFileReaderHandle(processController: processController)
        handle.cancel()
        
        XCTAssertFalse(processController.isProcessRunning)
    }
}

import Foundation
import ObservableFileReader
import ProcessController
import ProcessControllerTestHelpers
import XCTest

final class ProcessObservableFileReaderHandlerTests: XCTestCase {
    lazy var processController = FakeProcessController(subprocess: Subprocess(arguments: []))
    
    func test() {
        processController.start()
        
        let handler = ProcessObservableFileReaderHandler(processController: processController)
        handler.cancel()
        
        XCTAssertFalse(processController.isProcessRunning)
    }
}

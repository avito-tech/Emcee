import SignalHandling
import Signals
import XCTest

final class SignalHandlerTests: XCTestCase {
    func test___hanlder_fires_when_signal_occurs() {
        var didHandle = false
        
        SignalHandling.addSignalHandler(signal: Signal.user(20)) { value in
            XCTAssertEqual(value, 20)
            didHandle = true
        }
        
        Signals.raise(signal: Signals.Signal.user(20))
        
        XCTAssertTrue(didHandle)
    }
}

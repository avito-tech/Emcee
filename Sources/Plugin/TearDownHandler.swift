import EventBus
import Foundation

final class TearDownHandler: DefaultBusListener {
    private let onTearDown: () -> ()
    public init(onTearDown: @escaping () -> ()) {
        self.onTearDown = onTearDown
    }
    
    override func tearDown() {
        onTearDown()
    }
}

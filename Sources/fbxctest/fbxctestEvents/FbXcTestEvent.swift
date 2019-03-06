import Foundation

public final class FbXcTestEvent: Decodable {
    public let event: FbXcTestEventName
    
    public init(event: FbXcTestEventName) {
        self.event = event
    }
}

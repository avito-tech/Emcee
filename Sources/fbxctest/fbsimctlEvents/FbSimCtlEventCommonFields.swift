import Foundation

public protocol FbSimCtlEventCommonFields {
    var type: FbSimCtlEventType { get }
    var name: FbSimCtlEventName { get }
    var timestamp: TimeInterval { get }
}

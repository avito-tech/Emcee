import Foundation

public protocol EventStream {
    func process(event: BusEvent)
}

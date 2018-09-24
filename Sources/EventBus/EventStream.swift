import Foundation
import Models

public protocol EventStream {
    func process(event: BusEvent)
}

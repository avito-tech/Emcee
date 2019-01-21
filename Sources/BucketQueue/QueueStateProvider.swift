import Foundation
import Models

public protocol QueueStateProvider {
    var state: QueueState { get }
}

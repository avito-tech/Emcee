import Foundation
import Models

public protocol RunningQueueStateProvider {
    var runningQueueState: RunningQueueState { get }
}

import Dispatch
import DistWorkerModels
import Foundation
import Logging
import Models
import RequestSender
import RESTInterfaces
import RESTMethods
import RESTServer
import QueueCommunication
import WorkerAlivenessProvider

public final class ToggleWorkersSharingEndpoint: RESTEndpoint {
    private let poller: WorkerUtilizationStatusPoller
    
    public let path: RESTPath = RESTMethod.toggleWorkersSharing
    public let requestIndicatesActivity = false
    
    public init(poller: WorkerUtilizationStatusPoller) {
        self.poller = poller
    }
    
    public func handle(payload: WorkersSharingFeatureStatus) throws -> VoidPayload {
        switch payload {
        case .disabled:
            poller.stopPollingAndRestoreDefaultConfig()
        case .enabled:
            poller.startPolling()
        }
        
        return VoidPayload()
    }
}

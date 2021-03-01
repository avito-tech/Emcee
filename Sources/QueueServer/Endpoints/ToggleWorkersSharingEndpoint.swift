import Dispatch
import DistWorkerModels
import Foundation
import EmceeLogging
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
    
    public func handle(payload: ToggleWorkersSharingPayload) throws -> VoidPayload {
        Logger.debug("Change workers sharing feature state to: \(payload.status)")
        
        switch payload.status {
        case .disabled:
            poller.stopPollingAndRestoreDefaultConfig()
        case .enabled:
            poller.startPolling()
        }
        
        return VoidPayload()
    }
}

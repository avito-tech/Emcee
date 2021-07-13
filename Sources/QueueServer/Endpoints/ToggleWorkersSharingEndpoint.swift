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
    private let autoupdatingWorkerPermissionProvider: AutoupdatingWorkerPermissionProvider
    
    public let path: RESTPath = RESTMethod.toggleWorkersSharing
    public let requestIndicatesActivity = false
    
    public init(autoupdatingWorkerPermissionProvider: AutoupdatingWorkerPermissionProvider) {
        self.autoupdatingWorkerPermissionProvider = autoupdatingWorkerPermissionProvider
    }
    
    public func handle(payload: ToggleWorkersSharingPayload) throws -> VoidPayload {
        switch payload.status {
        case .disabled:
            autoupdatingWorkerPermissionProvider.stopUpdatingAndRestoreDefaultConfig()
        case .enabled:
            autoupdatingWorkerPermissionProvider.startUpdating()
        }
        
        return VoidPayload()
    }
}

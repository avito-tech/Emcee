import Dispatch
import DistWorkerModels
import Foundation
import EmceeLogging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import Swifter
import WorkerAlivenessProvider

public final class WhatIsMyIpEndpoint: RESTEndpoint {
    public let path: RESTPath = WhatIsMyIpRESTMethod()
    public let requestIndicatesActivity = false
    
    public init(
    ) {
    }
    
    public enum WhatIsMyIpError: Error, CustomStringConvertible {
        case missingMedatada
        
        public var description: String {
            switch self {
            case .missingMedatada:
                return "WhatIsMyIpEndpoint called without metadata"
            }
        }
    }
    
    public func handle(payload: WhatIsMyIpPayload) throws -> WhatIsMyIpResponse {
        throw WhatIsMyIpError.missingMedatada
    }
    
    public func handle(payload: WhatIsMyIpPayload, metadata: PayloadMetadata) throws -> WhatIsMyIpResponse {
        return WhatIsMyIpResponse(address: metadata.requesterAddress)
    }
}

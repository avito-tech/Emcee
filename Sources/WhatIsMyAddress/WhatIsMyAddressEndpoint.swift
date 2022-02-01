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

public final class WhatIsMyAddressEndpoint: RESTEndpoint {
    public let path: RESTPath = WhatIsMyAddressRESTMethod()
    public let requestIndicatesActivity = false
    
    public init(
    ) {
    }
    
    public enum WhatIsMyAddressError: Error, CustomStringConvertible {
        case missingMedatada
        
        public var description: String {
            switch self {
            case .missingMedatada:
                return "WhatIsMyAddressEndpoint called without metadata"
            }
        }
    }
    
    public func handle(payload: WhatIsMyAddressPayload) throws -> WhatIsMyAddressResponse {
        throw WhatIsMyAddressError.missingMedatada
    }
    
    public func handle(payload: WhatIsMyAddressPayload, metadata: PayloadMetadata) throws -> WhatIsMyAddressResponse {
        return WhatIsMyAddressResponse(address: metadata.requesterAddress)
    }
}

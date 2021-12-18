import DistWorkerModels
import Foundation
import QueueModels

public struct WhatIsMyIpResponse: Codable, Equatable {
    public let address: String
    
    public init(address: String) {
        self.address = address
    }
}

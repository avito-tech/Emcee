import DistWorkerModels
import Foundation
import QueueModels

public struct WhatIsMyAddressResponse: Codable, Equatable {
    public let address: String
    
    public init(address: String) {
        self.address = address
    }
}

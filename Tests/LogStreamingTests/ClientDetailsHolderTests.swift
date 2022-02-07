import Foundation
import LogStreaming
import LogStreamingModels
import QueueModels
import SocketModels
import TestHelpers
import XCTest

final class ClientDetailsHolderTests: XCTestCase {
    private lazy var holder = ClientDetailsHolderImpl()
    private lazy var bucketId = BucketId("bucketId")
    
    private lazy var clientDetails = ClientDetails(
        socketAddress: SocketAddress(host: "doesnotmatter", port: 1234),
        clientLogStreamingMode: .all
    )
    
    func test___associating() {
        holder.associate(bucketId: bucketId, clientDetails: clientDetails)
        
        assert {
            holder.clientDetails(bucketId: bucketId)
        } equals: {
            clientDetails
        }
        
        assert {
            holder.knownClientDetails
        } equals: {
            Set([clientDetails])
        }
    }
    
    func test_erasing() {
        holder.associate(bucketId: bucketId, clientDetails: clientDetails)
        holder.forget(clientDetails: clientDetails)
        
        assertTrue { holder.clientDetails(bucketId: bucketId) == nil }
        
        assert {
            holder.knownClientDetails
        } equals: {
            Set()
        }
    }
}


import Foundation
import RESTInterfaces

public protocol RESTEndpoint {
    associatedtype PayloadType: Decodable
    associatedtype ResponseType: Encodable
    
    var path: RESTPath { get }
    
    /// When request comes in, mark this as an activity that potentially should cause prolongation of queue lifetime and postpone its automatic termination.
    var requestIndicatesActivity: Bool { get }
    
    func handle(payload: PayloadType) throws -> ResponseType
}

import DistWorkerModels
import Foundation
import Logging
import RESTServer

public final class WorkerRESTServer {
    private let httpRestServer: HTTPRESTServer
    
    public init(httpRestServer: HTTPRESTServer) {
        self.httpRestServer = httpRestServer
    }
    
    public func setHandler<AI, AO>(
        currentlyProcessingBucketsHandler: RESTEndpointOf<AI, AO>
    ) {
        httpRestServer.setHandler(
            pathWithSlash: CurrentlyProcessingBuckets.path.withPrependedSlash,
            handler: currentlyProcessingBucketsHandler,
            requestIndicatesActivity: false
        )
    }
    
    public func start() throws -> Int {
        let port = try httpRestServer.start()
        Logger.debug("Started worker REST server on \(port) port")
        return port
    }
}

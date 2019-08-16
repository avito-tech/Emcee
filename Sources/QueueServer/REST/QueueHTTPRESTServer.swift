import AutomaticTermination
import Foundation
import Logging
import PortDeterminer
import RESTMethods
import Swifter

public final class QueueHTTPRESTServer {
    private let automaticTerminationController: AutomaticTerminationController
    private let localPortDeterminer: LocalPortDeterminer
    private let requestParser = QueueServerRequestParser()
    private let server = HttpServer()
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        localPortDeterminer: LocalPortDeterminer)
    {
        self.automaticTerminationController = automaticTerminationController
        self.localPortDeterminer = localPortDeterminer
    }
    
    public func setHandler<A1, A2, B1, B2, C1, C2, D1, D2, E1, E2, F1, F2, G1, G2, H1, H2, I1, I2>(
        bucketResultHandler: RESTEndpointOf<C1, C2>,
        dequeueBucketRequestHandler: RESTEndpointOf<B1, B2>,
        jobDeleteHandler: RESTEndpointOf<I1, I2>,
        jobResultsHandler: RESTEndpointOf<H1, H2>,
        jobStateHandler: RESTEndpointOf<G1, G2>,
        registerWorkerHandler: RESTEndpointOf<A1, A2>,
        reportAliveHandler: RESTEndpointOf<D1, D2>,
        scheduleTestsHandler: RESTEndpointOf<E1, E2>,
        versionHandler: RESTEndpointOf<F1, F2>)
    {
        server[RESTMethod.bucketResult.withPrependingSlash] = processRequest(endpoint: bucketResultHandler, indicateActivity: true)
        server[RESTMethod.getBucket.withPrependingSlash] = processRequest(endpoint: dequeueBucketRequestHandler, indicateActivity: false)
        server[RESTMethod.jobDelete.withPrependingSlash] = processRequest(endpoint: jobDeleteHandler, indicateActivity: true)
        server[RESTMethod.jobResults.withPrependingSlash] = processRequest(endpoint: jobResultsHandler, indicateActivity: true)
        server[RESTMethod.jobState.withPrependingSlash] = processRequest(endpoint: jobStateHandler, indicateActivity: false)
        server[RESTMethod.queueVersion.withPrependingSlash] = processRequest(endpoint: versionHandler, indicateActivity: false)
        server[RESTMethod.registerWorker.withPrependingSlash] = processRequest(endpoint: registerWorkerHandler, indicateActivity: true)
        server[RESTMethod.reportAlive.withPrependingSlash] = processRequest(endpoint: reportAliveHandler, indicateActivity: false)
        server[RESTMethod.scheduleTests.withPrependingSlash] = processRequest(endpoint: scheduleTestsHandler, indicateActivity: true)
    }

    private func processRequest<T, R>(
        endpoint: RESTEndpointOf<T, R>,
        indicateActivity: Bool
    ) -> ((HttpRequest) -> HttpResponse) {
        return { [weak self] (httpRequest: HttpRequest) -> HttpResponse in
            guard let strongSelf = self else {
                Logger.error("\(type(of: self)) has been deallocated")
                return .internalServerError
            }
            Logger.verboseDebug("Processing request to \(httpRequest.path)")
            
            if indicateActivity {
                strongSelf.automaticTerminationController.indicateActivityFinished()
            }
            
            return strongSelf.requestParser.parse(request: httpRequest) { decodedObject in
                try endpoint.handle(decodedRequest: decodedObject)
            }
        }
    }
    
    public func start() throws -> Int {
        let port = try localPortDeterminer.availableLocalPort()
        try server.start(in_port_t(port), forceIPv4: false, priority: .default)
        return port
    }
}

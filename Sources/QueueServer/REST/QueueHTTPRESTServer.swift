import Foundation
import PortDeterminer
import RESTMethods
import Swifter

public final class QueueHTTPRESTServer {
    private let server = HttpServer()
    private let localPortDeterminer: LocalPortDeterminer
    private let requestParser = QueueServerRequestParser()
    
    public init(localPortDeterminer: LocalPortDeterminer) {
        self.localPortDeterminer = localPortDeterminer
    }
    
    public func setHandler<A1, A2, B1, B2, C1, C2, D1, D2, E1, E2>(
        registerWorkerHandler: RESTEndpointOf<A1, A2>,
        dequeueBucketRequestHandler: RESTEndpointOf<B1, B2>,
        bucketResultHandler: RESTEndpointOf<C1, C2>,
        reportAliveHandler: RESTEndpointOf<D1, D2>,
        versionHandler: RESTEndpointOf<E1, E2>)
    {
        server[RESTMethod.registerWorker.withPrependingSlash] = processRequest(usingEndpoint: registerWorkerHandler)
        server[RESTMethod.getBucket.withPrependingSlash] = processRequest(usingEndpoint: dequeueBucketRequestHandler)
        server[RESTMethod.bucketResult.withPrependingSlash] = processRequest(usingEndpoint: bucketResultHandler)
        server[RESTMethod.reportAlive.withPrependingSlash] = processRequest(usingEndpoint: reportAliveHandler)
        server[RESTMethod.queueVersion.withPrependingSlash] = processRequest(usingEndpoint: versionHandler)
    }

    private func processRequest<T, R>(usingEndpoint endpoint: RESTEndpointOf<T, R>) -> ((HttpRequest) -> HttpResponse) {
        return { [weak self] (httpRequest: HttpRequest) -> HttpResponse in
            guard let strongSelf = self else { return .internalServerError }
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

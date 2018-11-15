import Foundation
import RESTMethods
import Swifter

public final class QueueHTTPRESTServer {
    private let server = HttpServer()
    private let requestParser = QueueServerRequestParser()
    
    public init() {}
    
    public func setHandler<A, B, C, D>(
        registerWorkerHandler: RESTEndpointOf<A>,
        bucketFetchRequestHandler: RESTEndpointOf<B>,
        bucketResultHandler: RESTEndpointOf<C>,
        reportAliveHandler: RESTEndpointOf<D>)
    {
        server[RESTMethod.registerWorker.withPrependingSlash] = processRequest(usingEndpoint: registerWorkerHandler)
        server[RESTMethod.getBucket.withPrependingSlash] = processRequest(usingEndpoint: bucketFetchRequestHandler)
        server[RESTMethod.bucketResult.withPrependingSlash] = processRequest(usingEndpoint: bucketResultHandler)
        server[RESTMethod.reportAlive.withPrependingSlash] = processRequest(usingEndpoint: reportAliveHandler)
    }

    private func processRequest<T>(usingEndpoint endpoint: RESTEndpointOf<T>) -> ((HttpRequest) -> HttpResponse) {
        return { [weak self] (httpRequest: HttpRequest) -> HttpResponse in
            guard let strongSelf = self else { return .internalServerError }
            return strongSelf.requestParser.parse(request: httpRequest) { decodedObject in
                try endpoint.handle(decodedRequest: decodedObject)
            }
        }
    }
    
    public func start() throws -> Int {
        try server.start(0, forceIPv4: false, priority: .default)
        return try server.port()
    }
}

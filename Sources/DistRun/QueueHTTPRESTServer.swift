import Foundation
import RESTMethods
import Swifter

public final class QueueHTTPRESTServer {
    private let server = HttpServer()
    private let requestParser = QueueServerRequestParser()
    
    public final class Endpoint<T: Decodable> {
        let responseProducer: (T) throws -> RESTResponse
        
        public init(_ responseProducer: @escaping (T) throws -> RESTResponse) {
            self.responseProducer = responseProducer
        }
    }
    
    public init() {}
    
    public func setEndpoints<A, B, C, D>(
        registerWorker: Endpoint<A>,
        getBucket: Endpoint<B>,
        bucketResult: Endpoint<C>,
        reportAlive: Endpoint<D>)
        where A: Decodable, B: Decodable, C: Decodable, D: Decodable
    {
        server[RESTMethod.registerWorker.withPrependingSlash] = processRequest(usingEndpoint: registerWorker)
        server[RESTMethod.getBucket.withPrependingSlash] = processRequest(usingEndpoint: getBucket)
        server[RESTMethod.bucketResult.withPrependingSlash] = processRequest(usingEndpoint: bucketResult)
        server[RESTMethod.reportAlive.withPrependingSlash] = processRequest(usingEndpoint: reportAlive)
    }
    
    private func processRequest<T>(
        usingEndpoint endpoint: Endpoint<T>)
        -> ((HttpRequest) -> HttpResponse)
        where T: Decodable
    {
        return { [weak self] (httpRequest: HttpRequest) -> HttpResponse in
            guard let strongSelf = self else { return .internalServerError }
            return strongSelf.requestParser.parse(
                request: httpRequest,
                responseProducer: endpoint.responseProducer)
        }
    }
    
    public func start() throws {
        try server.start(0, forceIPv4: false, priority: .default)
    }
    
    public func port() throws -> Int {
        return try server.port()
    }
}

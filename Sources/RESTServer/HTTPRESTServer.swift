import AutomaticTermination
import Foundation
import EmceeLogging
import PathLib
import RESTMethods
import SocketModels
import Vapor

public final class HTTPRESTServer {
    private let automaticTerminationController: AutomaticTerminationController
    private let logger: ContextualLogger
    private let portProvider: PortProvider
    private let requestParser = RequestParser()
    private let application = Application()
    private let useOnlyIPv4: Bool
    
    deinit {
        application.http.server.shared.shutdown()
        application.shutdown()
    }
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        logger: ContextualLogger,
        portProvider: PortProvider,
        useOnlyIPv4: Bool
    ) {
        self.automaticTerminationController = automaticTerminationController
        self.logger = logger
        self.portProvider = portProvider
        self.useOnlyIPv4 = useOnlyIPv4
    }

    public func add<Request, Response>(
        handler: RESTEndpointOf<Request, Response>
    ) {
        let responseHander = self.processRequest(
            endpoint: handler
        )
        
        application.on(
            Vapor.HTTPMethod.POST,
            handler.path.pathWithLeadingSlash.pathComponents,
            use: { request in
                try JSONResponseEncodableBox(value: responseHander(request))
            }
        )
    }
    
    public func add(
        requestPath: AbsolutePath,
        localFilePath: AbsolutePath
    ) {
        application.get(requestPath.pathString.pathComponents) { request in
            request.fileio.streamFile(at: localFilePath.pathString)
        }
//        server[requestPath.pathString] = shareFile(localFilePath.pathString)
    }

    private func processRequest<Endpoint: RESTEndpoint>(
        endpoint: Endpoint
    ) -> ((Request) throws -> Endpoint.ResponseType) {
        return { [weak self] (httpRequest: Request) throws -> Endpoint.ResponseType in
            guard let strongSelf = self else {
                throw Abort(.internalServerError, reason: "\(type(of: self)) has been deallocated")
            }
            strongSelf.logger.trace("Processing request to \(httpRequest.url)")
            
            if endpoint.requestIndicatesActivity {
                strongSelf.automaticTerminationController.indicateActivityFinished()
            }
            
            return try strongSelf.requestParser.parse(
                request: httpRequest
            ) { (decodedPayload: Endpoint.PayloadType) -> Endpoint.ResponseType in
                if let address = httpRequest.remoteAddress, let ipAddress = address.ipAddress {
                    return try endpoint.handle(
                        payload: decodedPayload,
                        metadata: PayloadMetadata(
                            requesterAddress: ipAddress
                        )
                    )
                } else {
                    return try endpoint.handle(payload: decodedPayload)
                }
            }
        }
    }
    
    @discardableResult
    public func start() throws -> SocketModels.Port {
        let port = try portProvider.localPort()
        
        application.http.server.configuration.port = port.value
        
        try application.http.server.shared.start()
        let promise = application.eventLoopGroup.next().makePromise(of: Void.self)
        application.running = .start(using: promise)
        promise.futureResult.whenFailure { [logger] error in
            logger.error("Rest server error \(error)")
        }
        
        let actualPort = application.http.server.shared.localAddress!.port!
        logger.info("Started REST server on \(actualPort) port")
        return Port(value: actualPort)
    }
    
    struct MyError: Error {}
    
    public func port() throws -> SocketModels.Port {
        guard application.running != nil else {
            throw MyError()
        }
        
        let server = application.http.server.shared
        guard let localAddress = server.localAddress else {
            throw MyError()
        }
        guard let port = localAddress.port else {
            throw MyError()
        }
        return Port(value: port)
    }
}

struct JSONResponseEncodableBox<T: Encodable>: ResponseEncodable {
    let value: T
    
    func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        request.eventLoop.makeSucceededFuture(
            Response(
                status: .ok,
                headers: ["content-type": "application/json"],
                body: .init(data: try! JSONEncoder().encode(value))
            )
        )
    }
}

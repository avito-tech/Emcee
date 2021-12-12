import AutomaticTermination
import Foundation
import EmceeLogging
import PathLib
import RESTMethods
import SocketModels
import Swifter

public final class HTTPRESTServer {
    private let automaticTerminationController: AutomaticTerminationController
    private let logger: ContextualLogger
    private let portProvider: PortProvider
    private let requestParser = RequestParser()
    private let server = HttpServer()
    private let useOnlyIPv4: Bool
    
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
        server[handler.path.pathWithLeadingSlash] = processRequest(
            endpoint: handler
        )
    }
    
    public func add(
        requestPath: AbsolutePath,
        localFilePath: AbsolutePath
    ) {
        server[requestPath.pathString] = shareFile(localFilePath.pathString)
    }

    private func processRequest<Endpoint: RESTEndpoint>(
        endpoint: Endpoint
    ) -> ((HttpRequest) -> HttpResponse) {
        return { [weak self] (httpRequest: HttpRequest) -> HttpResponse in
            guard let strongSelf = self else {
                return .raw(500, "Internal Server Error", [:]) {
                    try $0.write(Data("\(type(of: self)) has been deallocated".utf8))
                }
            }
            strongSelf.logger.trace("Processing request to \(httpRequest.path)")
            
            if endpoint.requestIndicatesActivity {
                strongSelf.automaticTerminationController.indicateActivityFinished()
            }
            
            return strongSelf.requestParser.parse(request: httpRequest) { (decodedPayload: Endpoint.PayloadType) -> Endpoint.ResponseType in
                if let address = httpRequest.address {
                    return try endpoint.handle(
                        payload: decodedPayload,
                        metadata: PayloadMetadata(
                            requesterAddress: address
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
        try server.start(in_port_t(port.value), forceIPv4: useOnlyIPv4, priority: .default)
        
        let actualPort = try server.port()
        logger.info("Started REST server on \(actualPort) port")
        return Port(value: actualPort)
    }
    
    public func port() throws -> SocketModels.Port {
        Port(value: try server.port())
    }
}

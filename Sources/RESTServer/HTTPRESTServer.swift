import AutomaticTermination
import Foundation
import Logging
import RESTMethods
import SocketModels
import Swifter

public final class HTTPRESTServer {
    private let automaticTerminationController: AutomaticTerminationController
    private let portProvider: PortProvider
    private let requestParser = RequestParser()
    private let server = HttpServer()
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        portProvider: PortProvider
    ) {
        self.automaticTerminationController = automaticTerminationController
        self.portProvider = portProvider
    }

    public func add<Request, Response>(
        handler: RESTEndpointOf<Request, Response>
    ) {
        server[handler.path.pathWithLeadingSlash] = processRequest(
            endpoint: handler
        )
    }

    private func processRequest<T, R>(
        endpoint: RESTEndpointOf<T, R>
    ) -> ((HttpRequest) -> HttpResponse) {
        return { [weak self] (httpRequest: HttpRequest) -> HttpResponse in
            guard let strongSelf = self else {
                Logger.error("\(type(of: self)) has been deallocated")
                return .internalServerError
            }
            Logger.verboseDebug("Processing request to \(httpRequest.path)")
            
            if endpoint.requestIndicatesActivity {
                strongSelf.automaticTerminationController.indicateActivityFinished()
            }
            
            return strongSelf.requestParser.parse(request: httpRequest) { decodedPayload in
                try endpoint.handle(payload: decodedPayload)
            }
        }
    }
    
    public func start() throws -> SocketModels.Port {
        let port = try portProvider.localPort()
        try server.start(in_port_t(port.value), forceIPv4: false, priority: .default)
        
        let actualPort = try server.port()
        Logger.debug("Started REST server on \(actualPort) port")
        return Port(value: actualPort)
    }
    
    public func port() throws -> SocketModels.Port {
        Port(value: try server.port())
    }
}

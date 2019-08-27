import AutomaticTermination
import Foundation
import Logging
import RESTMethods
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

    public func setHandler<Request, Response>(
        pathWithSlash: String,
        handler: RESTEndpointOf<Request, Response>,
        requestIndicatesActivity: Bool
    ) {
        server[pathWithSlash] = processRequest(endpoint: handler, indicateActivity: requestIndicatesActivity)
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
        let port = try portProvider.localPort()
        try server.start(in_port_t(port), forceIPv4: false, priority: .default)
        return port
    }
}

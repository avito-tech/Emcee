import Foundation
import EmceeLogging
import PluginSupport
import SynchronousWaiter
import Vapor

public final class EventDistributor {
    private let logger: ContextualLogger
    private var pluginIdentifiers = Set<String>()
    private var connectedPluginIdentifiers = Set<String>()
    private let application = Application()
    private let hostname: String
    private var webSocketSessions = [WebSocket]()
    private let queue = DispatchQueue(label: "EventDistributor.queue")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    deinit {
        application.http.server.shared.shutdown()
        application.shutdown()
    }
    
    public init(
        hostname: String,
        logger: ContextualLogger
    ) {
        self.hostname = hostname
        self.logger = logger
    }
    
    public func start() throws {
        try queue.sync {
            logger.trace("Starting web socket server")
//            server["/"] = websocket(text: nil, binary: onBinary, pong: nil, connected: nil, disconnected: nil)
//            let app =
            application.webSocket("") { request, websocket in
                websocket.onBinary { websocket, buffer in
                    self.onBinary(
                        websocket: websocket,
                        incomingData: Array(buffer: buffer)
                    )
                }
            }
            
            application.http.server.configuration.port = 0
            try application.http.server.shared.start()
        }
        logger.trace("Web socket server is available at: \(try webSocketAddress())")
    }
    
    public func stop() {
        queue.sync {
            logger.trace("Stopping web socket server")
            application.http.server.shared.shutdown()
            application.shutdown()
        }
    }
    
    public func add(pluginIdentifier: String) {
        pluginIdentifiers.insert(pluginIdentifier)
    }
    
    public func waitForPluginsToConnect(timeout: TimeInterval) throws {
        try SynchronousWaiter().waitWhile(pollPeriod: 0.5, timeout: timeout, description: "Waiting for \(pluginIdentifiers.count) plugins to connect") {
            connectedPluginIdentifiers != pluginIdentifiers
        }
    }
    
    public func webSocketAddress() throws -> String {
        return queue.sync {
            let port = application.http.server.shared.localAddress!.port!
            let address = "ws://\(hostname):\(port)/"
            return address
        }
    }
    
    public func send(data: Data) {
        queue.sync {
            let bytes = [UInt8](data)
            for session in webSocketSessions {
                let promise = session.eventLoop.makePromise(of: Void.self)
                session.send(bytes, promise: promise)
                // FIXME: Is this needed?
                do {
                    try promise.futureResult.wait()
                } catch {
                    logger.error("\(error)")
                }
            }
            // FIXME: ???
//            webSocketSessions.removeAll { $0.webSocketSession == nil }
        }
    }

    private func onBinary(websocket: WebSocket, incomingData: [UInt8]) -> Void {
        let data = Data(incomingData)
        
        let acknowledgement: PluginHandshakeAcknowledgement
        do {
            let handshakeRequest = try decoder.decode(PluginHandshakeRequest.self, from: data)
            if pluginIdentifiers.contains(handshakeRequest.pluginIdentifier) {
                connectedPluginIdentifiers.insert(handshakeRequest.pluginIdentifier)
                webSocketSessions.append(websocket)
                acknowledgement = .successful
            } else {
                acknowledgement = .error("Unknown plugin identifier: '\(handshakeRequest.pluginIdentifier)'")
            }
        } catch {
            acknowledgement = .error("Internal error: '\(error)'")
        }
        
        logger.trace("New connection from plugin with acknowledgement: '\(acknowledgement)'")
        
        do {
            let data = try encoder.encode(acknowledgement)
            let promise = websocket.eventLoop.makePromise(of: Void.self)
            promise.futureResult.whenFailure { [logger] error in
                logger.error("Error in socket write: \(error)")
            }
            websocket.send(
                [UInt8](data),
                promise: promise
            )
        } catch {
            logger.error("Failed to send acknowledgement: \(error)")
        }
    }
}

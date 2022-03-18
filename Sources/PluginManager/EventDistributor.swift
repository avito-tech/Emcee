import Foundation
import EmceeLogging
import PluginSupport
import Swifter
import SynchronousWaiter

public final class EventDistributor {
    private final class WeakWebSocketSession {
        weak var webSocketSession: WebSocketSession?

        public init(webSocketSession: WebSocketSession?) {
            self.webSocketSession = webSocketSession
        }
    }
    
    private let logger: ContextualLogger
    private var pluginIdentifiers = Set<String>()
    private var connectedPluginIdentifiers = Set<String>()
    private let server = HttpServer()
    private let hostname: String
    private var webSocketSessions = [WeakWebSocketSession]()
    private let queue = DispatchQueue(label: "EventDistributor.queue")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
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
            server["/"] = websocket(text: nil, binary: onBinary, pong: nil, connected: nil, disconnected: nil)
            try server.start(0, forceIPv4: false, priority: .default)
        }
        logger.trace("Web socket server is available at: \(try webSocketAddress())")
    }
    
    public func stop() {
        queue.sync {
            logger.trace("Stopping web socket server")
            server.stop()
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
        return try queue.sync {
            let port = try server.port()
            let address = "ws://\(hostname):\(port)/"
            return address
        }
    }
    
    public func send(data: Data) {
        queue.sync {
            let bytes = [UInt8](data)
            for session in webSocketSessions {
                session.webSocketSession?.writeBinary(bytes)
            }
            webSocketSessions.removeAll { $0.webSocketSession == nil }
        }
    }

    private func onBinary(session: WebSocketSession, incomingData: [UInt8]) -> Void {
        let data = Data(incomingData)
        
        let acknowledgement: PluginHandshakeAcknowledgement
        do {
            let handshakeRequest = try decoder.decode(PluginHandshakeRequest.self, from: data)
            if pluginIdentifiers.contains(handshakeRequest.pluginIdentifier) {
                connectedPluginIdentifiers.insert(handshakeRequest.pluginIdentifier)
                webSocketSessions.append(WeakWebSocketSession(webSocketSession: session))
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
            session.writeBinary([UInt8](data))
        } catch {
            logger.error("Failed to send acknowledgement: \(error)")
        }
    }
}

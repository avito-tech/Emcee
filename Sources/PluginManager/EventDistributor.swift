import Foundation
import HostDeterminer
import Logging
import Swifter
import SynchronousWaiter

public final class EventDistributor {
    private final class WeakWebSocketSession {
        weak var webSocketSession: WebSocketSession?

        public init(webSocketSession: WebSocketSession?) {
            self.webSocketSession = webSocketSession
        }
    }
    
    private var pluginIdentifiers = Set<String>()
    private var connectedPluginIdentifiers = Set<String>()
    private let server = HttpServer()
    private var webSocketSessions = [WeakWebSocketSession]()
    private let queue = DispatchQueue(label: "ru.avito.emcee.EventDistributor.queue")
    
    public init() {}
    
    public func start() throws {
        try queue.sync {
            log("Starting web socket server")
            server["/"] = websocket(onString, nil, nil)
            try server.start(0, forceIPv4: false, priority: .default)
        }
        log("Web socket server is available at: \(try webSocketAddress())")
    }
    
    public func stop() {
        queue.sync {
            log("Stopping web socket server")
            server.stop()
        }
    }
    
    public func add(pluginIdentifier: String) {
        pluginIdentifiers.insert(pluginIdentifier)
    }
    
    public func waitForPluginsToConnect(timeout: TimeInterval) throws {
        try SynchronousWaiter.waitWhile(pollPeriod: 0.5, timeout: timeout, description: "Waiting for all plugins to connect") {
            connectedPluginIdentifiers != pluginIdentifiers
        }
    }
    
    public func webSocketAddress() throws -> String {
        return try queue.sync {
            let host = HostDeterminer.currentHostAddress
            let port = try server.port()
            let address = "ws://\(host):\(port)/"
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
    
    private func onString(session: WebSocketSession, string: String) -> Void {
        if pluginIdentifiers.contains(string) {
            connectedPluginIdentifiers.insert(string)
            log("New web socket connection from plugin \(string): \(session)")
            webSocketSessions.append(WeakWebSocketSession(webSocketSession: session))
        }
    }
    
    private func onBinary(session: WebSocketSession, incomingData: [UInt8]) -> Void {
        
    }
}

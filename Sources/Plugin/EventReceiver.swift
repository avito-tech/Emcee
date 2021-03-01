import Foundation
import Starscream
import EmceeLogging
import PluginSupport

public final class EventReceiver: WebSocketDelegate {
    public typealias Handler = () -> ()
    public typealias ErrorHandler = (Swift.Error) -> ()
    public typealias DataHandler = (Data) -> ()
    
    private let address: String
    private let pluginIdentifier: String
    private let socket: WebSocket
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var didHandshake = false
    
    public var onDisconnect: Handler?
    public var onError: ErrorHandler?
    public var onData: DataHandler?
    
    public enum `Error`: Swift.Error, CustomStringConvertible {
        case acknowledgementError(message: String?)
        
        public var description: String {
            switch self {
            case .acknowledgementError(let message):
                return "Plugin acknowledgement error: \(message ?? "null message")"
            }
        }
    }

    public init(address: String, pluginIdentifier: String) {
        self.address = address
        self.pluginIdentifier = pluginIdentifier
        self.socket = WebSocket(url: URL(string: address)!)
    }
    
    public func start() {
        Logger.debug("Connecting to web socket: \(address)")
        didHandshake = false
        socket.delegate = self
        socket.connect()
    }
    
    public func stop() {
        Logger.debug("Disconnecting from web socket: \(address)")
        socket.disconnect()
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        Logger.verboseDebug("Connected to web socket")
        do {
            let handshakeRequest = PluginHandshakeRequest(pluginIdentifier: pluginIdentifier)
            let data = try encoder.encode(handshakeRequest)
            socket.write(data: data)
            Logger.debug("Sent handshake request")
        } catch {
            Logger.error("Failed to encode handshake request: \(error)")
        }
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Swift.Error?) {
        didHandshake = false
        if let error = error {
            if let wsError = error as? WSError, wsError.code == CloseCode.normal.rawValue {
                Logger.verboseDebug("Disconnected from web socket normally")
                onDisconnect?()
            } else {
                Logger.error("Web socket error: \(error)")
                onError?(error)
            }
        } else {
            Logger.verboseDebug("Disconnected from web socket without error")
            onDisconnect?()
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        Logger.debug("Received message from web socket: \(text)")
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        Logger.debug("Received data from web socket: \(data.count) bytes")
        
        if didHandshake {
            onData?(data)
        } else if let acknowledgement = try? decoder.decode(PluginHandshakeAcknowledgement.self, from: data) {
            switch acknowledgement {
            case .successful:
                didHandshake = true
            case .error(let message):
                onError?(Error.acknowledgementError(message: message))
            }
        } else {
            stop()
        }
    }
}

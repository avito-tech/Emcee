import Foundation
import Starscream
import Logging

public final class EventReceiver: WebSocketDelegate {
    public typealias Handler = () -> ()
    public typealias ErrorHandler = (Error) -> ()
    public typealias DataHandler = (Data) -> ()
    
    private let address: String
    private let socket: WebSocket
    public var onConnect: Handler?
    public var onDisconnect: Handler?
    public var onError: ErrorHandler?
    public var onData: DataHandler?

    public init(address: String) {
        self.address = address
        self.socket = WebSocket(url: URL(string: address)!)
    }
    
    public func start() {
        log("Connecting to web socket: \(address)")
        socket.delegate = self
        socket.connect()
    }
    
    public func stop() {
        log("Disconnecting from web socket: \(address)")
        socket.disconnect()
    }
    
    public func send(string: String) {
        socket.write(string: string)
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        log("Connected to web socket")
        onConnect?()
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let error = error {
            log("Web socket error: \(error)")
            onError?(error)
        } else {
            log("Disconnected from web socket")
            onDisconnect?()
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        log("Received message from web socket: \(text)")
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        log("Received data from web socket: \(data.count) bytes")
        onData?(data)
    }
}

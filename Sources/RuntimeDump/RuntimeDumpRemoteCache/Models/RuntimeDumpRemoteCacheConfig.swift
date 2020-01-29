import RequestSender
import Models

public final class RuntimeDumpRemoteCacheConfig {
    public let credentials: Credentials
    public let storeHttpMethod: HTTPMethod
    public let obtainHttpMethod: HTTPMethod
    public let pathToRemoteStorage: String
    public let socketAddress: SocketAddress
    
    public init(
        credentials: Credentials,
        storeHttpMethod: HTTPMethod,
        obtainHttpMethod: HTTPMethod,
        pathToRemoteStorage: String,
        socketAddress: SocketAddress
    ) {
        self.credentials = credentials
        self.storeHttpMethod = storeHttpMethod
        self.obtainHttpMethod = obtainHttpMethod
        self.pathToRemoteStorage = pathToRemoteStorage
        self.socketAddress = socketAddress
    }
}

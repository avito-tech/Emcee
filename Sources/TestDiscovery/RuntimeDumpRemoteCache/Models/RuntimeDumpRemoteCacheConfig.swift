import PathLib
import RequestSender
import SocketModels

public struct RuntimeDumpRemoteCacheConfig: Decodable, Equatable {
    public let credentials: Credentials
    public let storeHttpMethod: HTTPMethod
    public let obtainHttpMethod: HTTPMethod
    public let relativePathToRemoteStorage: RelativePath
    public let socketAddress: SocketAddress
    
    public init(
        credentials: Credentials,
        storeHttpMethod: HTTPMethod,
        obtainHttpMethod: HTTPMethod,
        relativePathToRemoteStorage: RelativePath,
        socketAddress: SocketAddress
    ) {
        self.credentials = credentials
        self.storeHttpMethod = storeHttpMethod
        self.obtainHttpMethod = obtainHttpMethod
        self.relativePathToRemoteStorage = relativePathToRemoteStorage
        self.socketAddress = socketAddress
    }
}

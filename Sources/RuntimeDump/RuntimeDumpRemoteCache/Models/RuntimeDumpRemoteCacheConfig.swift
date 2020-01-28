import RequestSender

public final class RuntimeDumpRemoteCacheConfig {
    public let credentials: Credentials
    public let storeHttpMethod: HTTPMethod
    public let obtainHttpMethod: HTTPMethod
    public let pathToRemoteStorage: String
    
    public init(
        credentials: Credentials,
        storeHttpMethod: HTTPMethod,
        obtainHttpMethod: HTTPMethod,
        pathToRemoteStorage: String
    ) {
        self.credentials = credentials
        self.storeHttpMethod = storeHttpMethod
        self.obtainHttpMethod = obtainHttpMethod
        self.pathToRemoteStorage = pathToRemoteStorage
    }
}

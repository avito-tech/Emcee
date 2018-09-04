import Foundation

public final class LaunchdSocket {
    public enum SocketType: String {
        /** TCP */
        case stream
        /** UDP */
        case dgram
    }
    
    public enum SocketPassivity {
        /** Socket will listen for the new connections */
        case listen
        /** Socket will connect */
        case connect
    }
    
    public enum ServiceReferenceType {
        /** "ssh", "http", etc. */
        case name(String)
        /** 443, 8888, etc. */
        case port(Int)
    }
    
    /** Type of socket */
    let socketType: SocketType
    /** The intention of the socket */
    let socketPassive: SocketPassivity
    /** Node to connected to, or host name, e.g. "localhost" */
    let socketNodeName: String
    /** SockServiceName value. Essentially this is the port, but can be expressed via service name. */
    let socketServiceReferenceType: ServiceReferenceType
    
    public init(
        socketType: SocketType,
        socketPassive: SocketPassivity,
        socketNodeName: String,
        socketServiceName: ServiceReferenceType)
    {
        self.socketType = socketType
        self.socketPassive = socketPassive
        self.socketNodeName = socketNodeName
        self.socketServiceReferenceType = socketServiceName
    }
}

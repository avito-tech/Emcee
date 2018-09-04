import Foundation

public final class LaunchdPlist {
    private let job: LaunchdJob

    public init(job: LaunchdJob) {
        self.job = job
    }

    public func createPlistData() throws -> Data {
        let contents = createPlistDict()
        return try PropertyListSerialization.data(fromPropertyList: contents, format: .xml, options: 0)
    }
    
    private func createPlistDict() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        dictionary["Label"] = job.label
        dictionary["ProgramArguments"] = job.programArguments
        dictionary["EnvironmentVariables"] = job.environmentVariables
        dictionary["WorkingDirectory"] = job.workingDirectory
        dictionary["RunAtLoad"] = job.runAtLoad
        dictionary["Disabled"] = job.disabled
        dictionary["StandardOutPath"] = job.standardOutRedirectionPath
        dictionary["StandardErrorPath"] = job.standardErrorRedirectionPath
        dictionary["Sockets"] = job.sockets.mapValues { (value: LaunchdSocket) -> NSDictionary in
            let socket = NSMutableDictionary()
            socket["SockType"] = value.socketType.rawValue
            socket["SockPassive"] = (value.socketPassive == .listen)
            socket["SockNodeName"] = value.socketNodeName
            switch value.socketServiceReferenceType {
            case .name(let name):
                socket["SockServiceName"] = name
            case .port(let port):
                socket["SockServiceName"] = NSNumber(value: port)
            }
            return socket
        }
        if job.inetdCompatibility != .disabled {
            let waitEnabled = job.inetdCompatibility == .enabledWithWait
            dictionary["inetdCompatibility"] = ["Wait": waitEnabled]
        }
        if job.sessionType != .aqua {
            dictionary["LimitLoadToSessionType"] = job.sessionType.rawValue
        }
        return dictionary
    }
}

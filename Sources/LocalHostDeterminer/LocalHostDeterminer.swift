import Foundation
import Logging

/**
 * This class attempts to read the current host name from the same source as `scutil --get HostName` does.
 * If there is no value present there, it falls back to getting host name from Host.current() API.
 * It is recommended to set the machine's host name via the following call:
 *
 *  sudo scutil --set HostName machine.example.com
 */
public final class LocalHostDeterminer {
    public static let currentHostAddress: String = {
        if let hostname = hostnameFromGetHostname(), !hostname.isEmpty {
            Logger.debug("Obtained host name using gethostname: '\(hostname)'")
            return hostname
        }
        
        if let hostname = hostnameFromHostCurrent(), !hostname.isEmpty {
            Logger.warning("Obtained host name using Host APIs: '\(hostname)'")
            return hostname
        }
        
        Logger.fatal("Unable to obtain address for current host")
    }()
    
    private static func hostnameFromHostCurrent() -> String? {
        let host = Host.current()
        return host.name ?? host.address
    }
    
    private static func hostnameFromGetHostname() -> String? {
        let maxLength = Int(_SC_HOST_NAME_MAX)
        var hostname = Array<Int8>(repeating: 0, count: maxLength)
        guard gethostname(&hostname, maxLength) == 0,
            let string = NSString(cString: hostname, encoding: String.Encoding.utf8.rawValue) else
        {
            return nil
        }
        return string as String
    }
}

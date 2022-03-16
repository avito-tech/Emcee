import EmceeDI
import EmceeLogging
import Foundation
import HostnameProvider

public enum HostnameSetup {
    public static func update(hostname: String, di: DI) throws {
        try di.get(MutableHostnameProvider.self)
            .set(hostname: hostname)
        
        di.set(
            try di.get(ContextualLogger.self)
                .withMetadata(key: .hostname, value: hostname)
        )
    }
}

import DateProvider
import EmceeExtensions
import EmceeLoggingModels
import Foundation
import Kibana
import MetricsExtensions

public final class KibanaLoggerHandler: LoggerHandler {
    public let dateProvider: DateProvider
    private let group = DispatchGroup()
    private let kibanaClient: KibanaClient
    
    public enum SkipMetadataFlags: String {
        case skippingKibana
    }
    
    public init(
        dateProvider: DateProvider,
        kibanaClient: KibanaClient
    ) {
        self.dateProvider = dateProvider
        self.kibanaClient = kibanaClient
    }
    
    public func handle(logEntry: LogEntry) {
        guard !logEntry.coordinates.contains(where: { $0.name == SkipMetadataFlags.skippingKibana.rawValue }) else {
            return
        }
        
        do {
            var kibanaPayload = [
                "fileLine": "\(logEntry.file):\(logEntry.line)"
            ]
            
            for keyValue in logEntry.coordinates {
                kibanaPayload[keyValue.name] = keyValue.value ?? "null"
            }
            
            group.enter()
            try kibanaClient.send(
                level: logEntry.verbosity.levelForKibana,
                message: logEntry.message,
                metadata: kibanaPayload
            ) { [group] _ in
                group.leave()
            }
        } catch {
            group.leave()
        }
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        _ = group.wait(timeout: .now() + timeout)
    }
}

extension ContextualLogger {
    public var skippingKibana: ContextualLogger {
        withMetadata(key: KibanaLoggerHandler.SkipMetadataFlags.skippingKibana.rawValue, value: nil)
    }
}

extension Verbosity {
    var levelForKibana: String {
        stringCode.lowercased()
    }
}

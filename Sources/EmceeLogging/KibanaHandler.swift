import EmceeExtensions
import Foundation
import Kibana
import Logging
import MetricsExtensions

public final class KibanaLoggerHandler: LoggerHandler {
    private let group = DispatchGroup()
    private let kibanaClient: KibanaClient
    
    public static let skipMetadataFlag = "skipKibana"
    
    public init(kibanaClient: KibanaClient) {
        self.kibanaClient = kibanaClient
    }
    
    public func handle(logEntry: LogEntry) {
        // no-op and should not be used.
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        _ = group.wait(timeout: .now() + timeout)
    }
    
    public func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        guard metadata?[Self.skipMetadataFlag] == nil else { return }
        
        var kibanaPayload = [
            "fileLine": "\(file.lastPathComponent):\(line)",
        ]
        
        for keyValue in metadata ?? [:] {
            switch keyValue.value {
            case let .string(value):
                kibanaPayload[keyValue.key] = value
            case let .stringConvertible(value):
                kibanaPayload[keyValue.key] = value.description
            case .array, .dictionary:
                break
            }
        }
        
        do {
            group.enter()
            try kibanaClient.send(
                level: level.rawValue,
                message: message.description,
                metadata: kibanaPayload
            ) { [group] _ in
                group.leave()
            }
        } catch {
            group.leave()
        }
    }
    
    public subscript(metadataKey _: String) -> Logging.Logger.Metadata.Value? {
        get { nil }
        set(newValue) {}
    }
    
    public var metadata: Logging.Logger.Metadata = [:]
    public var logLevel: Logging.Logger.Level = .debug
}

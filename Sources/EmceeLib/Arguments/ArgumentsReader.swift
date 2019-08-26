import Foundation
import LocalQueueServerRunner
import Logging
import Models
import ResourceLocationResolver

final class ArgumentsReader {
    private init() {}
    
    private static let decoderWithSnakeCaseSupport: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    private static let strictDecoder = JSONDecoder()
    
    public static func environment(_ file: String) throws -> [String: String] {
        return try decodeModelsFromFile(file, defaultValueIfFileIsMissing: [:], jsonDecoder: strictDecoder)
    }
    
    public static func testArgFile(_ file: String) throws -> TestArgFile {
        return try decodeModelsFromFile(file, jsonDecoder: strictDecoder)
    }
    
    public static func testDestinations(_ file: String) throws -> [TestDestinationConfiguration] {
        return try decodeModelsFromFile(file, jsonDecoder: decoderWithSnakeCaseSupport)
    }
    
    public static func deploymentDestinations(_ file: String) throws -> [DeploymentDestination] {
        return try decodeModelsFromFile(file, jsonDecoder: decoderWithSnakeCaseSupport)
    }
    
    public static func queueServerRunConfiguration(
        location: QueueServerRunConfigurationLocation,
        resourceLocationResolver: ResourceLocationResolver
    ) throws -> QueueServerRunConfiguration {
        let resolvingResult = try resourceLocationResolver.resolvePath(resourceLocation: location.resourceLocation)
        return try decodeModelsFromFile(
            try resolvingResult.directlyAccessibleResourcePath(),
            jsonDecoder: decoderWithSnakeCaseSupport
        )
    }
    
    private static func decodeModelsFromFile<T>(
        _ file: String,
        defaultValueIfFileIsMissing: T? = nil,
        jsonDecoder: JSONDecoder
    ) throws -> T where T: Decodable {
        if !FileManager.default.fileExists(atPath: file) {
            if let defaultValueIfFileIsMissing = defaultValueIfFileIsMissing {
                return defaultValueIfFileIsMissing
            }
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: file))
        return try jsonDecoder.decode(T.self, from: data)
    }
}

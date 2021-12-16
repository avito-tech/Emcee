import Deployer
import DistDeployer
import EmceeExtensions
import Foundation
import LocalQueueServerRunner
import ResourceLocationResolver
import TestArgFile
import TestDiscovery

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

    public static func remoteCacheConfig(_ file: String?) throws -> RuntimeDumpRemoteCacheConfig? {
        guard let file = file else {
            return nil
        }
        
        return try decodeModelsFromFile(file, jsonDecoder: decoderWithSnakeCaseSupport)
    }
    
    public static func queueServerConfiguration(
        location: QueueServerConfigurationLocation,
        resourceLocationResolver: ResourceLocationResolver
    ) throws -> QueueServerConfiguration {
        let resolvingResult = try resourceLocationResolver.resolvePath(resourceLocation: location.resourceLocation)
        return try decodeModelsFromFile(
            try resolvingResult.directlyAccessibleResourcePath().pathString,
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
        return try jsonDecoder.decodeExplaining(T.self, from: data, context: file)
    }
}

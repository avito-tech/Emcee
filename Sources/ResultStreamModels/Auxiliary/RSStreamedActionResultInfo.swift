import Foundation

public struct RSStreamedActionResultInfo: Codable, RSTypedValue, Equatable {
    public static let typeName = "StreamedActionResultInfo"
    
    public let resultIndex: RSInt
    
    public init(resultIndex: RSInt) {
        self.resultIndex = resultIndex
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultIndex = try container.decode(RSInt.self, forKey: .resultIndex)
    }
}

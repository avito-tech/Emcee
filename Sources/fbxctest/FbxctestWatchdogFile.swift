import Foundation

struct FbxctestWatchdogFile: Encodable {
    let bundleIds: [String]
    let timeout: Int
    
    enum CodingKeys: String, CodingKey {
        case bundleIds = "bundle_ids"
        case timeout = "timeout"
    }
}

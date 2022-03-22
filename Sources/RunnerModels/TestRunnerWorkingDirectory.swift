import Foundation
import PathLib

public struct TestRunnerWorkingDirectory: Codable, Hashable {
    public let path: AbsolutePath
    
    public init(path: AbsolutePath) {
        self.path = path
    }
    
    public var xcresultBundlePath: AbsolutePath {
        path.appending("resultBundle.xcresult")
    }
    
    public var resultStreamPath: AbsolutePath {
        path.appending("result_stream.json")
    }
    
    public var xctestRunPath: AbsolutePath {
        path.appending("testrun.xctestrun")
    }
    
    public var derivedDataPath: AbsolutePath {
        path.appending("derivedData")
    }
}

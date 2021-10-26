import Foundation
import ResultStreamModels
import PathLib

public protocol XcResultTool {
    func get(path: AbsolutePath) throws -> RSActionsInvocationRecord
}

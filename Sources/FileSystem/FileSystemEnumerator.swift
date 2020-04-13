import Foundation
import PathLib

public protocol FileSystemEnumerator {
    func each(iterator: (AbsolutePath) throws -> ()) throws
}

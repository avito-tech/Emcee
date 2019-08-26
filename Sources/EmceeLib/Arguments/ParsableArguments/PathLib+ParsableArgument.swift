import ArgLib
import Foundation
import PathLib

extension AbsolutePath: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        self.init(argumentValue)
    }
}

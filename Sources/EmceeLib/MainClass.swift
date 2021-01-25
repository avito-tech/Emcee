import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import ProcessController

public final class Main {
    public init() {}
    
    public func main() -> Int32 {
        do {
            try InProcessMain().run()
            return 0
        } catch {
            Logger.error("\(error)")
            return 1
        }
    }
}

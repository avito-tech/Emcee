import ArgumentsParser
import Foundation
import Logging
import ProcessController

func main() -> Int32 {
    return Main().main()
}

let exitCode = main()
exit(exitCode)

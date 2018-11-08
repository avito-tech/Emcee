import Foundation
import Logging

guard let outputPath = ProcessInfo.processInfo.environment["TEST_PLUGIN_OUTPUT_PATH"], !outputPath.isEmpty else {
    log("$TEST_PLUGIN_OUTPUT_PATH should be defined", color: .red)
    exit(1)
}

try TestPlugin(outputPath: outputPath).run()

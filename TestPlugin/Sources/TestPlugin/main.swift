import Foundation
import Logging

guard let outputPath = ProcessInfo.processInfo.environment["TEST_PLUGIN_OUTPUT_PATH"], !outputPath.isEmpty else {
    Logger.fatal("$TEST_PLUGIN_OUTPUT_PATH should be defined")
}

try TestPlugin(outputPath: outputPath).run()

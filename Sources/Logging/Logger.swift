import Foundation
import Ansi

// MARK: - Print log stating it belongs to fbxctest process with given pid

public func stdout_fbxctest(_ text: String, _ fbxctestProcessId: Int32, color: ConsoleColor = .none) {
    stdout(text, subprocessName: "fbxctest", subprocessId: fbxctestProcessId, color: color)
}

public func log_fbxctest(_ text: String, _ fbxctestProcessId: Int32, color: ConsoleColor = .none) {
    log(text, subprocessName: "fbxctest", subprocessId: fbxctestProcessId, color: color)
}

// MARK: - Print to stdout/err by applying NSLog-like format and color, subprocess info

public func stdout(_ text: String, subprocessName: String? = nil, subprocessId: Int32? = nil, color: ConsoleColor = .none) {
    formatlessStdout(formatTextForOutput(text, subprocessName: subprocessName, subprocessId: subprocessId, color: color))
}

public func log(_ text: String, subprocessName: String? = nil, subprocessId: Int32? = nil, color: ConsoleColor = .none) {
    formatlessStderr(formatTextForOutput(text, subprocessName: subprocessName, subprocessId: subprocessId, color: color))
}

public func fatalLogAndError(_ text: String, subprocessName: String? = nil, subprocessId: Int32? = nil, color: ConsoleColor = .red) -> Never {
    formatlessStderr(formatTextForOutput(text, subprocessName: subprocessName, subprocessId: subprocessId, color: color))
    fatalError(text)
}

// MARK: - Print to stdout/err without applying any format

public func formatlessStdout(_ text: String) {
    var stdout = FileHandle.standardOutput
    // swiftlint:disable:next print
    print(text, to: &stdout)
}

public func formatlessStderr(_ text: String) {
    var stderr = FileHandle.standardError
    // swiftlint:disable:next print
    print(text, to: &stderr)
}

// MARK: - Formatting stuff, private to this file

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

// 2018-03-29 19:05:01.994+0300
public let logDateFormatter: DateFormatter = {
    let logFormatter = DateFormatter()
    logFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZ"
    logFormatter.timeZone = TimeZone.current
    return logFormatter
}()
public let logDateStampLength = logDateFormatter.string(from: Date()).count

fileprivate func formatTextForOutput(_ text: String, subprocessName: String? = nil, subprocessId: Int32? = nil, color: ConsoleColor) -> String {
    let processInfo = ProcessInfo.processInfo
    let text = text.trimmingCharacters(in: CharacterSet.newlines)
    let timeStamp = logDateFormatter.string(from: Date())
    
    let result: String
    if let processName = subprocessName, let processId = subprocessId {
        result = "\(timeStamp) \(processInfo.processName)[\(processInfo.processIdentifier)] \(processName)[\(processId)]: \(text)"
    } else {
        result = "\(timeStamp) \(processInfo.processName)[\(processInfo.processIdentifier)] \(text)"
    }
    return result.with(consoleColor: color)
}

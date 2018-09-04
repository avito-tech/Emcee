import Foundation

public enum ConsoleColor: String {
  case reset = "\u{001B}[0;0m"
  case none = ""
  case black = "\u{001B}[0;30m"
  case boldBlack = "\u{001B}[1;30m"
  case blue = "\u{001B}[0;34m"
  case boldBlue = "\u{001B}[1;34m"
  case yellow = "\u{001B}[0;33m"
  case boldYellow = "\u{001B}[1;33m"
  case green = "\u{001B}[0;32m"
  case boldGreen = "\u{001B}[1;32m"
  case red = "\u{001B}[0;31m"
  case boldRed = "\u{001B}[1;31m"
}

public extension String {
  func with(consoleColor: ConsoleColor) -> String {
    if Ansi.isAnsiTerminal {
      return consoleColor.rawValue + self + ConsoleColor.reset.rawValue
    } else {
      return self
    }
  }
}

public final class Ansi {
  public static let isAnsiTerminal: Bool = {
    let environment = ProcessInfo.processInfo.environment
    return environment["TERM"] != nil &&
      environment["IS_ON_BUILD_MACHINE"] != "true" &&
      environment["TEAMCITY_VERSION"] == nil &&
      environment["AVITO_RUNNER_DISABLE_COLORS"] != "false"
  }()

  private init() {}
}

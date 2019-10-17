import Foundation

private func inShellWhitelist(_ codeUnit: UInt8) -> Bool {
    switch codeUnit {
    case UInt8(ascii: "a")...UInt8(ascii: "z"),
         UInt8(ascii: "A")...UInt8(ascii: "Z"),
         UInt8(ascii: "0")...UInt8(ascii: "9"),
         UInt8(ascii: "-"),
         UInt8(ascii: "_"),
         UInt8(ascii: "/"),
         UInt8(ascii: ":"),
         UInt8(ascii: "@"),
         UInt8(ascii: "%"),
         UInt8(ascii: "+"),
         UInt8(ascii: "="),
         UInt8(ascii: "."),
         UInt8(ascii: ","):
        return true
    default:
        return false
    }
}

public extension String {
    func shellEscaped() -> String {
        guard let blackListCharacterPosition = utf8.firstIndex(where: { !inShellWhitelist($0) }) else {
            return self
        }
        
        guard let singleQuotePosition = utf8[blackListCharacterPosition...].firstIndex(of: UInt8(ascii: "'")) else {
            return "'\(self)'"
        }
        
        var result = "'" + String(self[..<singleQuotePosition])
        
        for character in self[singleQuotePosition...] {
            if character == "'" {
                result += "'\\''"
            } else {
                result += String(character)
            }
        }
        
        result += "'"
        
        return result
    }
}

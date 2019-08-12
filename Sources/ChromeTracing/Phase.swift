import Extensions
import Foundation
import Models

public enum Phase: String, Encodable {
    case complete = "X"
    case instant = "i"
    case counter = "C"
}

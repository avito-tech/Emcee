import Foundation

public enum FbSimCtlEventType: String, Decodable {
    case started
    case discrete
    case ended
}

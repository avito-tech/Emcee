import Foundation

public enum FbSimCtlEventName: String, Decodable {
    case boot
    case log
    case listen
    case failure
    case create
    case delete
    case launch
    case state
}

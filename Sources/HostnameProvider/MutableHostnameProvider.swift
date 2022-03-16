import Foundation

public protocol MutableHostnameProvider: HostnameProvider {
    func set(hostname: String)
}

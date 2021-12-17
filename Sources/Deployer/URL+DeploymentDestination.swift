import Foundation
import PathLib

public struct UrlAnalysisError: Error, CustomStringConvertible {
    public let url: URL
    public let text: String
    
    public var description: String {
        return [
            "Provided URL is invalid: \(url)",
            text,
            "Please make sure your URL is correct",
            "You can use password based auth: ssh://username:PASSWORD@example.com",
            "You can use key based auth: ssh://username@example.com?custom_rsa",
            "You can provide key outside ~/.ssh: ssh://username@example.com#/absolute/path/to/custom_rsa",
            "By default Emcee will use ~/emcee.noindex as working directory, but you can alter it: ssh://username@example.com/Users/username/TestRunner",
        ].joined(separator: ".\n")
    }
}

extension URL {
    public func deploymentDestination() throws -> DeploymentDestination {
        guard let schemeValue = self.scheme else { throw UrlAnalysisError(url: self, text: "Missing scheme") }
        let scheme = schemeValue.lowercased()
        
        guard scheme == "ssh" else { throw UrlAnalysisError(url: self, text: "Only ssh:// URL scheme is supported") }
        guard let host = self.host else { throw UrlAnalysisError(url: self, text: "Missing host") }
        let port = self.port ?? 22
        guard let user = self.user else { throw UrlAnalysisError(url: self, text: "Missing user") }
        var path = self.path
        if path.isEmpty {
            path = "/Users/\(user)/emcee.noindex"
        }
        
        let authenticationType: DeploymentDestinationAuthenticationType
        if let password = self.password {
            authenticationType = .password(password)
        } else if let query = self.query {
            authenticationType = .keyInDefaultSshLocation(filename: query)
        } else if let fragment = self.fragment {
            authenticationType = .key(path: try AbsolutePath.validating(string: fragment))
        } else {
            throw UrlAnalysisError(url: self, text: "Can't determine authentication method")
        }
        
        return DeploymentDestination(
            host: host,
            port: Int32(port),
            username: user,
            authentication: authenticationType,
            remoteDeploymentPath: AbsolutePath(path)
        )
    }
}

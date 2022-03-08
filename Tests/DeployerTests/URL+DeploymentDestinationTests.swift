import Deployer
import Foundation
import PathLib
import TestHelpers
import XCTest

final class URL_DeploymentDestinationTests: XCTestCase {
    func test___password_auth() {
        let url = assertNotNil {
            URL(string: "ssh://user:pass@example.com:42/some/path")
        }
        
        assert {
            try url.deploymentDestination()
        } equals: {
            DeploymentDestination(
                host: "example.com",
                port: 42,
                username: "user",
                authentication: .password("pass"),
                remoteDeploymentPath: AbsolutePath("/some/path"),
                configuration: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration
            )
        }
    }
    
    func test___key_auth___in_default_location() {
        let url = assertNotNil {
            URL(string: "ssh://user@example.com/some/path?sshKeyName=some_id")
        }
        
        assert {
            try url.deploymentDestination()
        } equals: {
            DeploymentDestination(
                host: "example.com",
                port: 22,
                username: "user",
                authentication: .keyInDefaultSshLocation(filename: "some_id"),
                remoteDeploymentPath: AbsolutePath("/some/path"),
                configuration: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration
            )
        }
    }
    
    func test___key_auth___in_custom_location() {
        let url = assertNotNil {
            URL(string: "ssh://user@example.com/some/path?absoluteSshKeyPath=/path/to/some_id")
        }
        
        assert {
            try url.deploymentDestination()
        } equals: {
            DeploymentDestination(
                host: "example.com",
                port: 22,
                username: "user",
                authentication: .key(path: AbsolutePath("/path/to/some_id")),
                remoteDeploymentPath: AbsolutePath("/some/path"),
                configuration: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration
            )
        }
    }
    
    func test___requires_ssh_scheme() {
        assertThrows {
            try assertNotNil { URL(string: "http://user:pass@example.com:22/some/path") }.deploymentDestination()
        }
    }
    
    func test___requires_auth_method() {
        assertThrows {
            try assertNotNil { URL(string: "ssh://user@example.com/some/path") }.deploymentDestination()
        }
        
        assertDoesNotThrow {
            try assertNotNil { URL(string: "ssh://user@example.com/some/path?absoluteSshKeyPath=/path") }.deploymentDestination()
        }
    }
    
    func test___number_of_simulators() {
        let numberOfSimulators: UInt = 9
        let url = assertNotNil {
            URL(string: "ssh://user@example.com/some/path?absoluteSshKeyPath=/path/to/some_id&numberOfSimulators=\(numberOfSimulators)")
        }
        
        assert {
            try url.deploymentDestination()
        } equals: {
            DeploymentDestination(
                host: "example.com",
                port: 22,
                username: "user",
                authentication: .key(path: AbsolutePath("/path/to/some_id")),
                remoteDeploymentPath: AbsolutePath("/some/path"),
                configuration: WorkerSpecificConfiguration(
                    numberOfSimulators: numberOfSimulators,
                    maximumCacheSize: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration.maximumCacheSize,
                    maximumCacheTTL: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration.maximumCacheTTL
                )
            )
        }
    }
    
    func test___default_values() {
        let url = assertNotNil {
            URL(string: "ssh://user:pass@example.com")
        }
        
        assert {
            try url.deploymentDestination()
        } equals: {
            DeploymentDestination(
                host: "example.com",
                port: 22,
                username: "user",
                authentication: .password("pass"),
                remoteDeploymentPath: AbsolutePath("/Users/user/emcee.noindex"),
                configuration: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration
            )
        }
    }
}

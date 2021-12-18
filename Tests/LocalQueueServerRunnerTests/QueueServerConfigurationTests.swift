import AutomaticTermination
import Deployer
import Foundation
import LocalQueueServerRunner
import MetricsExtensions
import LoggingSetup
import QueueModels
import QueueServerConfiguration
import SocketModels
import TestHelpers
import XCTest

final class QueueServerConfigurationTests: XCTestCase {
    func test___parsing() throws {
        let data = Data(
            """
                {
                  "globalAnalyticsConfiguration": {
                    "graphiteConfiguration": {
                      "socketAddress": "host:123",
                      "metricPrefix": "graphite.prefix"
                    },
                    "statsdConfiguration": {
                      "socketAddress": "host:123",
                      "metricPrefix": "statsd.prefix"
                    }
                  },
                  "workerSpecificConfigurations": {
                    "worker_1": {
                      "numberOfSimulators": 1
                    },
                    "worker_2": {
                      "numberOfSimulators": 2
                    },
                    "worker_3": {
                      "numberOfSimulators": 3
                    }
                  },
                  "queueServerDeploymentDestinations": [{
                    "host": "queue",
                    "port": 22,
                    "username": "q_user",
                    "authentication": {
                        "password": "pass"
                    },
                    "remoteDeploymentPath": "/remote/queue/depl/path"
                  }],
                  "queueServerTerminationPolicy": {
                    "caseId": "stayAlive"
                  },
                  "checkAgainTimeInterval": 22,
                  "workerDeploymentDestinations": [
                    {
                      "host": "host",
                      "port": 1,
                      "username": "username",
                      "authentication": {
                          "password": "pass"
                      },
                      "remoteDeploymentPath": "/remote/deployment/path"
                    }
                  ],
                  "workerStartMode": "unknownWayOfStartingWorkers"
                }
            """.utf8
        )
        
        let config = try JSONDecoder().decode(QueueServerConfiguration.self, from: data)
        XCTAssertEqual(
            config.globalAnalyticsConfiguration,
            AnalyticsConfiguration(
                graphiteConfiguration: MetricConfiguration(socketAddress: SocketAddress(host: "host", port: 123), metricPrefix: "graphite.prefix"),
                statsdConfiguration: MetricConfiguration(socketAddress: SocketAddress(host: "host", port: 123), metricPrefix: "statsd.prefix")
            )
        )
        XCTAssertEqual(
            config.workerSpecificConfigurations,
            [
                WorkerId("worker_1"): WorkerSpecificConfiguration(numberOfSimulators: 1),
                WorkerId("worker_2"): WorkerSpecificConfiguration(numberOfSimulators: 2),
                WorkerId("worker_3"): WorkerSpecificConfiguration(numberOfSimulators: 3),
            ]
        )
        XCTAssertEqual(
            config.queueServerDeploymentDestinations,
            [DeploymentDestination(host: "queue", port: 22, username: "q_user", authentication: .password("pass"), remoteDeploymentPath: "/remote/queue/depl/path")]
        )
        XCTAssertEqual(
            config.queueServerTerminationPolicy,
            AutomaticTerminationPolicy.stayAlive
        )
        XCTAssertEqual(
            config.checkAgainTimeInterval,
            22
        )
        XCTAssertEqual(
            config.workerDeploymentDestinations,
            [
                DeploymentDestination(host: "host", port: 1, username: "username", authentication: .password("pass"), remoteDeploymentPath: "/remote/deployment/path")
            ]
        )
        assert {
            config.workerStartMode
        } equals: {
            WorkerStartMode.unknownWayOfStartingWorkers
        }
    }
    
    func test___deployment_destination_with_key_parsing() throws {
        let data = Data("""
            {
                "host": "host",
                "port": 1,
                "username": "username",
                "authentication": {
                    "keyPath": "/path/to/key"
                },
                "remoteDeploymentPath": "/remote/deployment/path"
            }
        """.utf8
        )
        let config = try JSONDecoder().decode(DeploymentDestination.self, from: data)
        XCTAssertEqual(
            config,
            DeploymentDestination(host: "host", port: 1, username: "username", authentication: .key(path: "/path/to/key"), remoteDeploymentPath: "/remote/deployment/path")
        )
    }
    
    func test___deployment_destination_with_default_location_key_parsing() throws {
        let data = Data("""
            {
                "host": "host",
                "port": 1,
                "username": "username",
                "authentication": {
                    "filename": "key"
                },
                "remoteDeploymentPath": "/remote/deployment/path"
            }
        """.utf8
        )
        let config = try JSONDecoder().decode(DeploymentDestination.self, from: data)
        XCTAssertEqual(
            config,
            DeploymentDestination(host: "host", port: 1, username: "username", authentication: .keyInDefaultSshLocation(filename: "key"), remoteDeploymentPath: "/remote/deployment/path")
        )
    }
}

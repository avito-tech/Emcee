import ArgLib
import Deployer
import EmceeLogging
import Foundation
import EmceeDI
import LocalQueueServerRunner
import MetricsExtensions
import PathLib
import QueueModels
import SocketModels

public final class InitQueueServerConfigCommand: Command {
    public let name = "initQueueServerConfig"
    public let description = "Generates a sample queue server configuration file"
    public let arguments: Arguments = [
        ArgumentDescriptions.output.asRequired,
    ]
    
    private let logger: ContextualLogger
    
    public init(
        di: DI
    ) throws {
        self.logger = try di.get()
    }
    
    public func run(payload: CommandPayload) throws {
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)

        let config = QueueServerConfiguration(
            globalAnalyticsConfiguration: AnalyticsConfiguration(
                graphiteConfiguration: MetricConfiguration(
                    socketAddress: SocketAddress(
                        host: "graphite.example.com — this is a host name which runs Graphite instance, and its port. Please also refer to https://github.com/avito-tech/Emcee/wiki/Graphite",
                        port: 42
                    ),
                    metricPrefix: "some.prefix.for.emcee"
                ),
                statsdConfiguration: MetricConfiguration(
                    socketAddress: SocketAddress(
                        host: "statsd.example.com — this is a host name which runs Statsd instance, and its port. Please also refer to https://github.com/avito-tech/Emcee/wiki/Graphite",
                        port: 1234
                    ),
                    metricPrefix: "some.prefix.for.emcee"
                ),
                kibanaConfiguration: KibanaConfiguration(
                    endpoints: [
                        URL(string: "http://kibana.example.com:12345/")!,
                    ],
                    indexPattern: "E.g. 'emcee-index-16112021-' — please refer to https://github.com/avito-tech/Emcee/wiki/Analytics#kibana"
                ),
                persistentMetricsJobId: "Usually you pass 'nil' here, because global analytics are not bound to any specific test jobs",
                metadata: [
                    "WhatToPutHere": "Usually you'd put an empty dict here '{}', because these events are top level ones, but you can add any metadata as needed",
                ]
            ),
            checkAgainTimeInterval: 30,
            queueServerDeploymentDestinations: [
                DeploymentDestination(
                    host: "emceequeue.example.com - host name where queue should be started, and SSH port",
                    port: 22,
                    username: "ssh username to use",
                    authentication: DeploymentDestinationAuthenticationType.password("ssh password. But you can auth by key too!"),
                    remoteDeploymentPath: AbsolutePath("Working directory for EmceeQueueServer process. It should be writable by the provided username. Emcee will upload itself into this folder and start queue in daemon mode by using launchd. It will create plist and use launchctl (without sudo) to spawn a new daemon. Emcee queue has built-in protection to avoid starting multiple similar queues on the same machine.")
                )
            ],
            queueServerTerminationPolicy: .stayAlive,
            workerDeploymentDestinations: [
                DeploymentDestination(
                    host: "emceeWorker01.example.com - host name where WORKER should be started, and SSH port",
                    port: 22,
                    username: "ssh username to use on this worker. We recommend creating a separate standard user for this.",
                    authentication: DeploymentDestinationAuthenticationType.key(path: "/arbitrary/path/to/key.pub - you can pass any absolute path"),
                    remoteDeploymentPath: AbsolutePath("Working directory for EmceeWorker process on this host. It should be writable by the provided username. Emcee will upload itself into this folder and start worker in daemon mode by using launchd. It will create plist and use launchctl (without sudo) to spawn a new daemon. Worker will die right after queue dies.")
                ),
                DeploymentDestination(
                    host: "emceeWorker02.example.com - host name where WORKER should be started, and SSH port",
                    port: 22,
                    username: "emcee",
                    authentication: DeploymentDestinationAuthenticationType.keyInDefaultSshLocation(filename: "key name inside ~/.ssh - most common location for SSH keys"),
                    remoteDeploymentPath: AbsolutePath("/Users/emcee/worker/")
                )
            ],
            defaultWorkerSpecificConfiguration: WorkerSpecificConfiguration(numberOfSimulators: 3),
            workerSpecificConfigurations: [
                WorkerId(value: "emceeWorker01.example.com - use to specify special settings") : WorkerSpecificConfiguration(numberOfSimulators: 5),
            ],
            workerStartMode: .queueStartsItsWorkersOverSshAndLaunchd
        )
        
        let data = try JSONEncoder.pretty().encode(config)
        try data.write(to: outputPath.fileUrl)
        
        logger.info("Generated queue server configuration file stored at \(outputPath)")
    }
}

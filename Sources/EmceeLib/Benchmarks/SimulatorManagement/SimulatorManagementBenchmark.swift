import Benchmarking
import EmceeLogging
import Foundation
import SimulatorPool
import SimulatorPoolModels
import RunnerModels

public final class SimulatorManagementBenchmark: Benchmark {
    private let measurer: Measurer
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let simulatorOperationTimeouts = SimulatorOperationTimeouts(
        create: 180,
        boot: 600,
        delete: 300,
        shutdown: 300,
        automaticSimulatorShutdown: 9999,
        automaticSimulatorDelete: 9999
    )
    private let onDemandSimulatorPoolKey: OnDemandSimulatorPoolKey
    
    public var name: String {
        "Simulator management benchmark"
    }
    
    public init(
        measurer: Measurer,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        onDemandSimulatorPoolKey: OnDemandSimulatorPoolKey
    ) {
        self.measurer = measurer
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.onDemandSimulatorPoolKey = onDemandSimulatorPoolKey
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        do {
            let simulatorPool = try onDemandSimulatorPool.pool(key: onDemandSimulatorPoolKey)
            
            let simulatorController = try simulatorPool.allocateSimulatorController()
            simulatorController.apply(simulatorOperationTimeouts: simulatorOperationTimeouts)
            
            return run(
                contextualLogger: contextualLogger,
                simulatorController: simulatorController
            )
        } catch {
            return ErrorBenchmarkResult(error: error)
        }
    }
    
    private func run(
        contextualLogger: ContextualLogger,
        simulatorController: SimulatorController
    ) -> SimulatorManagementBenchmarkResult {
        contextualLogger.info("Measuring simulator operation: create")
        let createMeasurement = measurer.measure {
            try simulatorController.createdSimulator()
        }
        
        contextualLogger.info("Measuring simulator operation: boot")
        let bootMeasurement = measurer.measure {
            try simulatorController.bootedSimulator()
        }
        
        return SimulatorManagementBenchmarkResult(
            create: createMeasurement,
            boot: bootMeasurement
        )
    }
}

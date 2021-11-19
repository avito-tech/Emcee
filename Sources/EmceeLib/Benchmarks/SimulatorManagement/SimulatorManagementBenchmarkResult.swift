import Benchmarking
import Foundation
import PlistLib
import SimulatorPoolModels
//
//public struct SimulatorManagementBenchmarkResult: BenchmarkResult {
//    public let create: MeasurementResult<Simulator>
//    public let boot: MeasurementResult<Simulator>
//    
//    public init(
//        create: MeasurementResult<Simulator>,
//        boot: MeasurementResult<Simulator>
//    ) {
//        self.create = create
//        self.boot = boot
//    }
//    
//    public func plistEntry() -> PlistEntry {
//        return PlistEntry.dict([
//            "create": .number(create.duration),
//            "boot": .number(boot.duration),
//            
//            "createIsSuccess": .bool(create.result.isSuccess),
//            "bootIsSuccess": .bool(boot.result.isSuccess),
//        ])
//    }
//}

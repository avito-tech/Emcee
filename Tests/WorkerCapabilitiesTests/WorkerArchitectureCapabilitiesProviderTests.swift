//
//  File.swift
//  
//
//  Created by a.smolianin on 25.08.2022.
//

import Foundation
import XCTest
import WorkerCapabilities
import WorkerCapabilitiesModels


class WorkerArchitectureCapabilitiesProviderTests: XCTestCase {
    func test___x86_architecture() throws {
        class IntelXeon: CommandExecutor {
            func executeCommandWithOutput(env: Dictionary<String,String>, arguments: [String]) throws -> String {
                return "Intel(R) Xeon(R) W-3245 CPU @ 3.20GHz"
            }
        }
        
        let archProvider = WorkerArchitectureCapabilitiesProvider(logger: .noOp, commandExecutor: IntelXeon())
        XCTAssertEqual(Set([WorkerCapability(name: WorkerCapabilityName("emcee.arch"), value: "x86")]), archProvider.workerCapabilities())
    }
    
    func test___m1_architecture() throws {
        class M1: CommandExecutor {
            func executeCommandWithOutput(env: Dictionary<String,String>, arguments: [String]) throws -> String {
                return "Apple M1"
            }
        }

        let archProvider = WorkerArchitectureCapabilitiesProvider(logger: .noOp, commandExecutor: M1())
        XCTAssertEqual(Set([WorkerCapability(name: WorkerCapabilityName("emcee.arch"), value: "m1")]), archProvider.workerCapabilities())
    }

    func test___unknown_architecture() throws {
        class Unknown: CommandExecutor {
            func executeCommandWithOutput(env: Dictionary<String,String>, arguments: [String]) throws -> String {
                return "Something unknown"
            }
        }

        let archProvider = WorkerArchitectureCapabilitiesProvider(logger: .noOp, commandExecutor: Unknown())
        XCTAssertEqual(Set([WorkerCapability(name: WorkerCapabilityName("emcee.arch"), value: "unknown")]), archProvider.workerCapabilities())
    }
}

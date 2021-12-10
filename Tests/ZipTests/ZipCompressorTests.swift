import Foundation
import PathLib
import ProcessControllerTestHelpers
import TestHelpers
import Zip
import XCTest

final class ZipCompressorTests: XCTestCase {
    lazy var processControllerProvider = FakeProcessControllerProvider()
    lazy var compressor = ZipCompressorImpl(
        processControllerProvider: processControllerProvider
    )
    
    func test() throws {
        let validated = XCTestExpectation()
        processControllerProvider.creator = { subprocess in
            defer {
                validated.fulfill()
            }
            
            assert {
                try subprocess.arguments.map { try $0.stringValue() }
            } equals: {
                ["/usr/bin/zip", "/where/to/create/archive.zip", "-r", "what/to/compress/file.or.dir"]
            }
            
            let controller = FakeProcessController(subprocess: subprocess)
            controller.overridedProcessStatus = .terminated(exitCode: 0)
            return controller
        }
        
        _ = try compressor.createArchive(
            archivePath: AbsolutePath("/where/to/create/archive.zip"),
            workingDirectory: AbsolutePath("/where/contents/is/located"),
            contentsToCompress: RelativePath("what/to/compress/file.or.dir")
        )
        
        wait(for: [validated], timeout: 15)
    }
}

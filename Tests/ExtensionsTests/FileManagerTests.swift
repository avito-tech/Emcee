import Foundation
import Tmp
import XCTest

public class FileManagerTests: XCTestCase {
    
    let tempFolder = try! TemporaryFolder(deleteOnDealloc: true)

    func testWalkingUp() throws {
        let marker = "marker.txt"
        
        let deepHierarchy = tempFolder.absolutePath.appending(components: ["subfolder1", "subfolder2"])
        try touchFile(tempFolder.absolutePath.appending(component: marker).pathString)
        
        try FileManager.default.createDirectory(
            atPath: deepHierarchy.pathString,
            withIntermediateDirectories: true
        )
        let markerContainer = FileManager.default.walkUpTheHierarchy(
            path: deepHierarchy.pathString,
            untilFileIsFound: marker
        )
        XCTAssertEqual(
            markerContainer,
            tempFolder.absolutePath.pathString
        )
    }
    
    private func prepareFiles(names: [String]) throws -> [String] {
        let absolutePaths = names.map { tempFolder.absolutePath.appending(component: $0).pathString }
        for path in absolutePaths {
            try touchFile(path)
        }
        return absolutePaths
    }
    
    private func touchFile(_ path: String) throws {
        try Data().write(to: URL(fileURLWithPath: path), options: .atomicWrite)
    }
}

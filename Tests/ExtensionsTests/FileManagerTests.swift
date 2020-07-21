import Foundation
import TemporaryStuff
import XCTest

public class FileManagerTests: XCTestCase {
    
    let tempFolder = try! TemporaryFolder(deleteOnDealloc: true)
    
    func testExists() throws {
        let paths = try prepareFiles(names: ["first", "second"])
        XCTAssertTrue(FileManager.default.filesExist(paths))
    }
    
    func testSomeFilesDoNotExist() throws {
        var paths = try prepareFiles(names: ["first", "second"])
        paths.append(paths[0] + "_non_existing")
        XCTAssertFalse(FileManager.default.filesExist(paths))
    }
    
    func testFindFiles() throws {
        let prefix = UUID().uuidString
        let suffix = "_suffix"
        let ext = "file_extension"
        let names = [0, 1, 2, 3].map { prefix + "--\($0)--" + suffix + "." + ext }
        
        let absolutePaths1 = try prepareFiles(names: names)
        let absolutePaths2 = try prepareFiles(names: ["some_file1.some", "some_file2.some"])
        
        let foundFiles1 = try FileManager.default.findFiles(
            path: tempFolder.absolutePath.pathString,
            prefix: prefix,
            suffix: suffix,
            pathExtension: ext)
        XCTAssertEqual(foundFiles1.sorted(), absolutePaths1.sorted())
        
        let foundFiles2 = try FileManager.default.findFiles(
            path: tempFolder.absolutePath.pathString,
            prefix: "some_file",
            pathExtension: "some")
        XCTAssertEqual(foundFiles2.sorted(), absolutePaths2.sorted())
        
        let foundFiles3 = FileManager.default.findFiles(
            path: "/tmp/" + UUID().uuidString,
            pathExtension: "",
            defaultValue: ["default"])
        XCTAssertEqual(foundFiles3, ["default"])
    }
    
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
    
    func testIteratingDirectories() throws {
        try FileManager.default.createDirectory(atPath: tempFolder.absolutePath.appending(component: "folder1"))
        try FileManager.default.createDirectory(atPath: tempFolder.absolutePath.appending(component: "folder2"))
        try FileManager.default.createDirectory(atPath: tempFolder.absolutePath.appending(component: "folder3"))
        
        let expectedContents = Set(
            [
                tempFolder.absolutePath.appending(component: "folder1").pathString,
                tempFolder.absolutePath.appending(component: "folder2").pathString,
                tempFolder.absolutePath.appending(component: "folder3").pathString
            ]
        )
        let contents = try FileManager.default.findFiles(path: tempFolder.absolutePath.pathString)
        XCTAssertEqual(Set(contents), expectedContents)
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

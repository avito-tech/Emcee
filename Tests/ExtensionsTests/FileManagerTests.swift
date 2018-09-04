import Basic
import Extensions
import Foundation
import XCTest

public class FileManagerTests: XCTestCase {
    
    var tempFolder: TemporaryDirectory?
    
    enum `Error`: String, Swift.Error {
        case noTempFolder = "Expected to have a temp folder"
    }
    
    public override func setUp() {
        self.tempFolder = try? TemporaryDirectory(removeTreeOnDeinit: true)
    }
    
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
        guard let tempFolder = self.tempFolder else {
            XCTFail("Expected to have temp folder")
            return
        }
        
        let prefix = UUID().uuidString
        let suffix = "_suffix"
        let ext = "file_extension"
        let names = [0, 1, 2, 3].map { prefix + "--\($0)--" + suffix + "." + ext }
        
        let absolutePaths1 = try prepareFiles(names: names)
        let absolutePaths2 = try prepareFiles(names: ["some_file1.some", "some_file2.some"])
        
        let foundFiles1 = try FileManager.default.findFiles(
            path: tempFolder.path.asString,
            prefix: prefix,
            suffix: suffix,
            pathExtension: ext)
        XCTAssertEqual(foundFiles1.sorted(), absolutePaths1.sorted())
        
        let foundFiles2 = try FileManager.default.findFiles(
            path: tempFolder.path.asString,
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
        guard let tempFolder = self.tempFolder else { throw Error.noTempFolder }
        
        let marker = "marker.txt"
        
        let deepHierarchy = tempFolder.path.appending(components: "subfolder1", "subfolder2")
        try touchFile(tempFolder.path.appending(component: marker).asString)
        
        try FileManager.default.createDirectory(
            atPath: deepHierarchy.asString,
            withIntermediateDirectories: true,
            attributes: nil)
        let markerContainer = FileManager.default.walkUpTheHierarchy(
            path: deepHierarchy.asString,
            untilFileIsFound: marker)
        XCTAssertEqual(markerContainer, tempFolder.path.asString)
    }
    
    func testIteratingDirectories() throws {
        guard let tempFolder = self.tempFolder else { throw Error.noTempFolder }
        
        try FileManager.default.createDirectory(atPath: tempFolder.path.appending(component: "folder1").asString, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: tempFolder.path.appending(component: "folder2").asString, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: tempFolder.path.appending(component: "folder3").asString, withIntermediateDirectories: true, attributes: nil)
        
        let expectedContents = Set([
            tempFolder.path.appending(component: "folder1").asString,
            tempFolder.path.appending(component: "folder2").asString,
            tempFolder.path.appending(component: "folder3").asString
            ])
        let contents = try FileManager.default.findFiles(path: tempFolder.path.asString)
        XCTAssertEqual(Set(contents), expectedContents)
    }
    
    private func prepareFiles(names: [String]) throws -> [String] {
        guard let tempFolder = self.tempFolder else { throw Error.noTempFolder }
        
        let absolutePaths = names.map { tempFolder.path.appending(component: $0).asString }
        for path in absolutePaths {
            try touchFile(path)
        }
        return absolutePaths
    }
    
    private func touchFile(_ path: String) throws {
        try Data().write(to: URL(fileURLWithPath: path), options: .atomicWrite)
    }
}

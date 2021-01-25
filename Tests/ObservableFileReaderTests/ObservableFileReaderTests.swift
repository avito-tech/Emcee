import DateProvider
import FileSystem
import Foundation
import ObservableFileReader
import PathLib
import ProcessController
import TemporaryStuff
import TestHelpers
import XCTest

final class ObservableFileReaderTests: XCTestCase {
    lazy var tempFile = assertDoesNotThrow { try TemporaryFile() }
    
    func test() throws {
        let reader = try ObservableFileReaderImpl(
            path: tempFile.absolutePath,
            processControllerProvider: DefaultProcessControllerProvider(
                dateProvider: SystemDateProvider(),
                fileSystem: LocalFileSystem()
            )
        )
        
        let collectedTabSymbol = XCTestExpectation()
        
        var collectedContents = ""
        let handler = try reader.read { data in
            guard let string = String(data: data, encoding: .utf8) else { return }
            collectedContents.append(string)
            
            if string.contains("\t") {
                collectedTabSymbol.fulfill()
            }
        }
        
        tempFile.fileHandleForWriting.write("hello")
        tempFile.fileHandleForWriting.write(" world")
        tempFile.fileHandleForWriting.write("\n123\n")
        tempFile.fileHandleForWriting.write("\t")
        
        wait(for: [collectedTabSymbol], timeout: 15)
        handler.cancel()
        
        XCTAssertEqual(collectedContents, "hello world\n123\n\t")
    }
}

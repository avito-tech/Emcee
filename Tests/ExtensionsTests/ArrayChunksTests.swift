import XCTest
@testable import Extensions

class ArrayChunksTests: XCTestCase {
    func test_obviousExamples() {
        XCTAssertEqual(
            [0, 1].splitToChunks(withSize: 1),
            [
                [0],
                [1]
            ]
        )
        
        XCTAssertEqual(
            [0, 1].splitToChunks(withSize: 2),
            [
                [0, 1],
            ]
        )
        
        XCTAssertEqual(
            [].splitToChunks(withSize: 1),
            [] as [[Int]]
        )
        
        XCTAssertEqual(
            [0].splitToChunks(withSize: 1),
            [
                [0]
            ]
        )
        
        XCTAssertEqual(
            [0, 1, 2].splitToChunks(withSize: 2),
            [
                [0, 1],
                [2]
            ]
        )
        
        XCTAssertEqual(
            [0, 1, 2, 3].splitToChunks(withSize: 2),
            [
                [0, 1],
                [2, 3]
            ]
        )
        
        XCTAssertEqual(
            [0, 1, 2, 3].splitToChunks(withSize: 4),
            [
                [0, 1, 2, 3]
            ]
        )
        
        XCTAssertEqual(
            [0, 1, 2, 3].splitToChunks(withSize: 5),
            [
                [0, 1, 2, 3]
            ]
        )
    }
    
    func test_zeroChunkSize() {
        XCTAssertEqual(
            [0, 1].splitToChunks(withSize: 0),
            [
                [0, 1]
            ]
        )
    }
    
    func test_onDifferentData1() {
        // count: 1
        // source:  0 1
        // target: |0|1|
        //
        // count: 2
        // source:  0 1 2
        // target: |0 1|2|
        //
        // count: 3
        // source:  0 1 2 3
        // target: |0 1 2|3
        
        for count in 1..<100 {
            let source = Array(0...count)
            let target: [[Int]] = [
                Array(0..<count),
                [count]
            ]
            
            XCTAssertEqual(
                source.splitToChunks(withSize: UInt(count)),
                target
            )
        }
    }
    
    func test_onDifferentData2() {
        // count: 1
        // source:  0
        // target: |0|
        //
        // count: 2
        // source:  0 1
        // target: |0 1|
        //
        // count: 3
        // source:  0 1 2
        // target: |0 1 2|
        
        for count in 1..<100 {
            let source = Array(0..<count)
            let target: [[Int]] = [
                source
            ]
            
            XCTAssertEqual(
                source.splitToChunks(withSize: UInt(count)),
                target
            )
        }
    }
    
    func testProgressiveSplit() {
        let array = [1,2,3,4,5,6,7,8,9,0]
        
        let chunks = array.splitToVariableChunks(withStartingRelativeSize: 0.5, changingRelativeSizeBy: 0.5)
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1,2,3,4,5])
        XCTAssertEqual(chunks[1], [6,7,8])
        XCTAssertEqual(chunks[2], [9,0])
    }
    
    func testProgressiveSplitWithNoSizeChange() {
        let array = [1,2,3,4,5,6,7,8]
        
        let chunks = array.splitToVariableChunks(withStartingRelativeSize: 0.25)
        XCTAssertEqual(chunks.count, 4)
        XCTAssertEqual(chunks[0], [1,2])
        XCTAssertEqual(chunks[1], [3,4])
        XCTAssertEqual(chunks[2], [5,6])
        XCTAssertEqual(chunks[3], [7,8])
    }
    
    func testProgressiveSplitWithLargeFirstChunk() {
        let array = [1,2,3,4,5,6,7,8]
        
        let chunks = array.splitToVariableChunks(withStartingRelativeSize: 0.75)
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0], [1,2,3,4,5,6])
        XCTAssertEqual(chunks[1], [7,8])
    }
    
    func testProgressiveSplitWithEmptyArray() {
        let array: [Int] = []
        
        let chunks = array.splitToVariableChunks(withStartingRelativeSize: 0.5)
        XCTAssertEqual(chunks.count, 0)
    }
    
    func testProgressiveSplitBigStepProducesChunksWithAtLeastSingleElement() {
        let array = [1,2,3,4,5,6,7,8,9]
        
        let chunks = array.splitToVariableChunks(withStartingRelativeSize: 0.001, changingRelativeSizeBy: 0.001)
        XCTAssertEqual(chunks.count, 9)
        for chunk in chunks {
            XCTAssertEqual(chunk.count, 1)
        }
    }
    
    func testProgressiveSplitWithMinimumRelativeSize() {
        let array = [1,2,3,4,5,6,7,8,9,0,11,22,33,44,55,66,77,88,99,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35]
        
        let chunks = array.splitToVariableChunks(
            withStartingRelativeSize: 0.4,
            changingRelativeSizeBy: 0.5,
            minimumRelativeSize: 0.1)
        XCTAssertEqual(chunks.count, 6)
        XCTAssertEqual(chunks[0], [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 11, 22, 33, 44])
        XCTAssertEqual(chunks[1], [55, 66, 77, 88, 99, 20, 21])
        XCTAssertEqual(chunks[2], [22, 23, 24, 25])
        XCTAssertEqual(chunks[3], [26, 27, 28, 29])
        XCTAssertEqual(chunks[4], [30, 31, 32, 33])
        XCTAssertEqual(chunks[5], [34, 35])
    }
}

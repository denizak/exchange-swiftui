//
//  XCTest+MemoryLeak.swift
//  valas-swiftuiTests
//
//  Created by deni zakya on 27.12.25.
//

import Foundation
import XCTest

extension XCTestCase {
    func testMemoryLeak(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}

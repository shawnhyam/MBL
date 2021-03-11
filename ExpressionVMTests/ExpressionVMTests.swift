//
//  ExpressionVMTests.swift
//  ExpressionVMTests
//
//  Created by Shawn Hyam on 2021-03-04.
//

import XCTest
@testable import ExpressionVM
import Expression

class ExpressionVMTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSamples() throws {

        for (str, _, value) in createSamples(Value.init(integerLiteral:), Value.init(booleanLiteral:)) {
            let tokenizer = Tokenizer(str[...])
            var parser = Parser(tokenizer)
            let expr = try parser.parse()

            let result = ExprVM.eval(expr)
            
            XCTAssertEqual(value, result, str)
        }

    }
}

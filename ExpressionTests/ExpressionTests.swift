//
//  ExpressionTests.swift
//  ExpressionTests
//
//  Created by Shawn Hyam on 2021-03-04.
//

import XCTest
@testable import Expression

class ExpressionTests: XCTestCase {

    func testSamples() throws {

        for (str, type, _) in createSamples({ _ in () }, { _ in ()} ) {
            let tokenizer = Tokenizer(str[...])
            var parser = Parser(tokenizer)
            let expr = try parser.parse()

            var inferencer = Inferencer()
            let t = inferencer.infer(expr)
            XCTAssertEqual(t, type, "Failed: \(str)")

        }

    }

}

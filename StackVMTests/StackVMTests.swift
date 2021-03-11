//
//  StackVMTests.swift
//  StackVMTests
//
//  Created by Shawn Hyam on 2021-03-04.
//

import XCTest
import Expression
@testable import StackVM

class StackVMTests: XCTestCase {
    func testSamples() throws {

        for (str, _, value) in createSamples(Value.init(integerLiteral:), Value.init(booleanLiteral:)) {
            let tokenizer = Tokenizer(str[...])
            var parser = Parser(tokenizer)
            let expr = try parser.parse()
            let program = expr.compile(CompileEnv())

            var vm = VM(program: program)
            while vm.step() {

            }
            XCTAssertEqual(value, vm.acc, str)
        }
    }

}

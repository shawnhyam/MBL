//
//  ForthVMTests.swift
//  ForthVMTests
//
//  Created by Shawn Hyam on 2021-03-05.
//

import XCTest
import Expression
@testable import ForthVM

class ForthVMTests: XCTestCase {
    func testSamples() throws {

        for (str, _, value) in createSamples({ UInt16($0) }, { b in b ? UInt16(1) : 0 }) {
            let tokenizer = Tokenizer(str[...])
            var parser = Parser(tokenizer)
            let expr = try parser.parse()

            var env = CompileEnv()
            let program = expr.compile(&env)

            var machine = ForthVM(program: program)
            while machine.step() {
                // print(machine.dStack, machine.mem[13])
            }
            let result = machine.dStack.last!
            XCTAssertEqual(value, result, str)
        }

    }

    func testCompiler() throws {
        let tests: [(String, Value)] = [
            ( "4" , 4 ),
//            ( "(lambda (x) x)", .closure(.init(body: 2, values: [])) ),
            ( "((lambda () 42))", 42 ),
            ( "(let ((x 3)) (- x x))", 0 ),
            ( "(- (- 7 2) (- 5 4))", 4 ),
            ( "((lambda (n m) (- n m)) 5 3)", 2 ),
            ( "((lambda (y) ((lambda (x) (- x y)) 5)) 3)", 2 ),
            ( "(let ((x 3) (y 7)) (- y x))", 4 ),
            ( "(= 1 1)", 1 ),
//            ( "(if (= 3 3) #f #t)", 0 ),
//            ( "(if (= 3 4) #f #t)", 1 ),
//            ( "(begin 3 4)", 4 ),
//            ( "(= (= 2 2) (= #t #t))", 1 ),
//            ( "(time)", 0 ),
//            ( "((lambda (f) (f 3)) (lambda (x) x))", 3)
        ]

        for (str, value) in tests {
            let tokenizer = Tokenizer(str[...])
            //while case let .success(token) = tokenizer.eat() {
            //    print(token)
            //}
            var parser = Parser(tokenizer)
            let expr = try parser.parse()

            var env = CompileEnv()
            let program = expr.compile(&env)

            var machine = ForthVM(program: program)
//            program.map { $0.machineCode }.enumerated().forEach { idx, code in machine.mem[idx] = code }
            while machine.step() {
                print(machine.dStack, machine.mem[13])
            }
            let result = machine.dStack.last!
            print(value == result, result)
            assert(value == result)
        }
    }


}

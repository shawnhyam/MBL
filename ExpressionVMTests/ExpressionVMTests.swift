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

    func testExample() throws {
        let tests: [(String, Value)] = [
            ( "4" , .int(4) ),
//            ( "(lambda (x) x)", .closure(.init(body: 2, values: [])) ),
            ( "((lambda () 42))", 42 ),
            ( "(- (- 7 2) (- 5 4))", 4 ),
            ( "((lambda (n m) (- n m)) 5 3)", 2 ),
            ( "((lambda (y) ((lambda (x) (- x y)) 5)) 3)", 2 ),
            ( "(let ((x 3) (y 7)) (- y x))", 4 ),
            ( "(= 1 1)", true ),
            ( "(if (= 3 3) #f #t)", false ),
            ( "(if (= 3 4) #f #t)", true ),
            ( "(begin 3 4)", 4 ),
            ( "(= (= 2 2) (= #t #t))", true ),
            ( "(time)", 0 ),
            ( "((lambda (f) (f 3)) (lambda (x) x))", 3)
        ]
        
        for (str, value) in tests {
            let tokenizer = Tokenizer(str[...])
            //while case let .success(token) = tokenizer.eat() {
            //    print(token)
            //}
            var parser = Parser(tokenizer)
            let expr = try parser.parseExpr()
            let taggedExpr = expr.applyTags()

            let result = ExprVM.eval(taggedExpr)
            
            print(value == result, result)
        }

    }
}

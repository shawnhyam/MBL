//
//  SampleExpressions.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-09.
//

import Foundation

public func createSamples<Value>(_ fn1: (Int) -> Value, _ fn2: (Bool) -> Value) -> [(String, Type, Value)] {
    let samples: [(String, Type, Value)] = [
        ( "4" , .int, fn1(4) ),
        //            ( "(lambda (x) x)", .closure(.init(body: 2, values: [])) ),
        ( "((lambda () 42))", .int, fn1(42) ),
        ( "(- (- 7 2) (- 5 4))", .int, fn1(4) ),
        ( "((lambda (n m) (- n m)) 5 3)", .int, fn1(2) ),
        ( "((lambda (y) ((lambda (x) (- x y)) 5)) 3)", .int, fn1(2) ),
        ( "(let ((x 3) (y 7)) (- y x))", .int, fn1(4) ),
        ( "(= 1 1)", .bool, fn2(true) ),
        ( "(if (= 3 3) #f #t)", .bool, fn2(false) ),
        ( "(if (= 3 4) #f #t)", .bool, fn2(true) ),
        ( "(begin 3 4)", .int, fn1(4) ),
        ( "(= (= 2 2) (= #t #t))", .bool, fn2(true) ),
        ( "(time)", .int, fn1(0) ),
        ( "((lambda (f) (f 3)) (lambda (x) x))", .int, fn1(3) ),
        ( "(letrec ((fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1))))))) (fact 10))", .int, fn1(3628800)), 

    ]
    return samples
}

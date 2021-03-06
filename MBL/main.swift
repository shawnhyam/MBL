//
//  main.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation
import StackVM
import Expression


let tests: [(String, Value, Type)] = [
    ( "4" , .int(4), .int ),
    ( "(lambda (x) x)", .closure(.init(body: .abs(2), values: [])), .arrow([.var("τ1"), .var("τ1")]) ),
    ( "((lambda () 42))", 42, .int ),
    ( "(- (- 7 2) (- 5 4))", 4, .int ),
    ( "((lambda (n m) (- n m)) 5 3)", 2, .int ),
    ( "((lambda (y) ((lambda (x) (- x y)) 5)) 3)", 2, .int ),
    ( "(let ((x 3) (y 7)) (- y x))", 4, .int ),
    ( "(let ((x 37)) (let ((y 14)) (let ((z 3)) (- x (- y z)))))", 26, .int ),
    ( "(= 1 1)", true, .bool ),
    ( "(if (= 3 3) #f #t)", false, .bool ),
    ( "(if (= 3 4) #f #t)", true, .bool ),
    ( "(begin 3 4)", 4, .int ),
    ( "(= (= 2 2) (= #t #t))", true, .bool ),
    ( "(time)", 2, .int ),
    ( "((lambda (x y) ((lambda (y x) (if y x 0)) x y)) #t 8)", 8, .int ),
   // ( "((lambda (f) (f 3)) (lambda (x) x))", 3, .int),
   // ( "(letrec (f (x) (if (= x 0) 0 (f (- x 1)))) (f 3))", 0, .int )
//     ( "(let ((bar (fix foo (x) (if (= x 0) 0 (foo (- x 1)))))) (bar 3))", 0, .int )

]

// ( "(letrec (f (x) (if (= x 0) 0 (f (- x 1)))) (f 3))", 0, .int )
// ( "(let ((bar (lambda (x) x))) (bar 3))", 0, .int )
// ( "((lambda (f) (f 3)) (lambda (x) x))", 3, .int )
// ( "(let ((bar (fix foo (x) (if (= x 0) 0 (foo (- x 1)))))) (bar 3))", 0, .int )
// ( "(fix id (x) (id x))", 0, .arrow([.var("τ2"), .var("τ3")]) )

for (str, value, type) in tests {
    let tokenizer = Tokenizer(str[...])
    //while case let .success(token) = tokenizer.eat() {
    //    print(token)
    //}
    var parser = Parser(tokenizer)
    let expr = try parser.parse()

    var inferencer = Inferencer()
    let t = inferencer.infer(expr)
    assert(t == type)

    var inf2 = Inferencer()
    let types = inf2.inferAll(expr)
    print(">>>", expr.findEscapingClosures(types).isEmpty)

    let program = expr.compile(CompileEnv())
    var vm = VM(program: program)
    while vm.step() {
        
    }
    print(value == vm.acc, vm.acc)
    assert(value == vm.acc)
}

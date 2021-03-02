//
//  main.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation



let tests: [(String, Value, Type)] = [
    ( "4" , .int(4), .int ),
    ( "(lambda (x) x)", .closure(.init(body: 2, values: [])), .arrow([.var("τ1"), .var("τ1")]) ),
    ( "((lambda () 42))", 42, .int ),
    ( "(- (- 7 2) (- 5 4))", 4, .int ),
    ( "((lambda (n m) (- n m)) 5 3)", 2, .int ),
    ( "((lambda (y) ((lambda (x) (- x y)) 5)) 3)", 2, .int ),
    ( "(let (x 3) x)", 3, .int ),
    ( "(= 1 1)", true, .bool ),
    ( "(if (= 3 3) #f #t)", false, .bool ),
    ( "(if (= 3 4) #f #t)", true, .bool ),
    ( "(begin 3 4)", 4, .int )
]

for (str, value, type) in tests {
    let tokenizer = Tokenizer(str[...])
    //while case let .success(token) = tokenizer.eat() {
    //    print(token)
    //}
    var parser = Parser(tokenizer)
    let expr = try parser.parseExpr()
    let taggedExpr = expr.applyTags()
    
    var inferencer = Inferencer()
    let t = inferencer.infer(taggedExpr)
    assert(t == type)
    
    let program = taggedExpr.compile(CompileEnv())
    var vm = VM(program: program)
    while vm.step() {
        
    }
    print(value == vm.acc, vm.acc)
}

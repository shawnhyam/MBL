//
//  Parser.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation


enum ParseError: Error {
    case fail
    case token(TokError)
}


struct Parser {
    var tokenizer: Tokenizer
    
    init(_ tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }
 
    mutating func parseExpr() throws -> Expr<Void> {
        switch tokenizer.peek() {
        case let .failure(error):
            fatalError()
        case let .success(token):
            switch token {
            case .lparen:
                tokenizer.eat(.lparen)
                let result = try parseFoo()
                let _ = tokenizer.eat(.rparen)
                return result
            case let .id(id):
                tokenizer.eat(.id(id))
                return .var(id, ())
            case let .num(n):
                tokenizer.eat(.num(n))
                return .lit(.int(n), ())
            case let .bool(b):
                tokenizer.eat(token)
                return .lit(.bool(b), ())
            default:
                fatalError()
            }
        }
    }
    
    mutating func parseFoo() throws -> Expr<Void> {
        switch tokenizer.peek() {
        case let .failure(error):
            fatalError()
        case let .success(token):
            
            if token == .id("lambda") {
                return try parseLambda()
            } else if token == .id("let") {
                return try parseLet()
            } else if token == .id("if") {
                return try parseIf()
            } else if token == .id("begin") {
                return try parseSequence()
            } else {
                var exprs: [Expr<Void>] = []
                while tokenizer.peek() != .success(.rparen) {
                    let expr = try parseExpr()
                    exprs.append(expr)
                }
                return .app(exprs[0], Array(exprs[1...]), ())
            }
        }
    }
    
    mutating func parseIf() throws -> Expr<Void> {
        tokenizer.eat(.id("if"))
        let pred = try parseExpr()
        let then = try parseExpr()
        let else_ = try parseExpr()
        return .cond(pred, then, else_, ())
    }

    mutating func parseSequence() throws -> Expr<Void> {
        tokenizer.eat(.id("begin"))
        var result: [Expr<Void>] = []
        while .success(.rparen) != tokenizer.peek() {
            result.append(try parseExpr())
        }

        return .seq(result, ())
    }


    mutating func parseLet() throws -> Expr<Void> {
        tokenizer.eat(.id("let"))
        tokenizer.eat(.lparen)
        let v = try parseVar()
        let binding = try parseExpr()
        tokenizer.eat(.rparen)

        let body = try parseExpr()
        return .let(v, binding, body, ())
    }

    mutating func parseLambda() throws -> Expr<Void> {
        //tokenizer.eat(.lparen)  // lparen
        tokenizer.eat(.id("lambda"))  // lambda
        tokenizer.eat(.lparen)
        let vars = try parseVars()
        tokenizer.eat(.rparen)
        let body = try parseExpr()
        //tokenizer.eat(.rparen)
        return .abs(vars, body, ())
    }
    
    mutating func parseVar() throws -> Variable {
        guard case let .success(.id(id)) = tokenizer.peek() else { fatalError() }
        tokenizer.eat()
        return id
    }
    
    mutating func parseVars() throws -> [Variable] {
        var result: [Variable] = []
        while case let .success(.id(id)) = tokenizer.peek() {
            result.append(id)
            tokenizer.eat()
        }
        return result
    }
}

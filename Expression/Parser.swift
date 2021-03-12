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


public struct Parser {
    var tokenizer: Tokenizer
    
    public init(_ tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }

    public mutating func parse() throws -> Expr<Int> {
//        var exprs: [Expr<Void>] = []
//
//        while true {
//            switch tokenizer.peek() {
//            case .failure(.endOfInput):
//                return .seq(exprs, ())
//            case .failure(_):
//                fatalError()
//            case .success(_):
//                exprs.append(try parseExpr())
//            }
//        }
        return try parseExpr()
            .renameVariables()
            .rewriteAppliedLambdas()
            .fixLetrec()
            .applyTags()
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
            } else if token == .id("letrec") {
                return try parseLetrec()
            } else if token == .id("if") {
                return try parseIf()
            } else if token == .id("begin") {
                return try parseSequence()
            } else if token == .id("fix") {
                return try parseFix()
            } else if token == .id("set!") {
                return try parseSet()
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

        var vars: [Variable] = []
        var bindings: [Expr<Void>] = []

        while tokenizer.peek() == .success(.lparen) {
            tokenizer.eat(.lparen)
            vars.append(try parseVar())
            bindings.append(try parseExpr())
            tokenizer.eat(.rparen)
        }

        tokenizer.eat(.rparen)

        let body = try parseExpr()
        return .let(vars, bindings, body, ())
    }

    mutating func parseSet() throws -> Expr<Void> {
        tokenizer.eat(.id("set!"))
        let name = try parseVar()
        let body = try parseExpr()
        return .set(name, body, ())
    }

    mutating func parseFix() throws -> Expr<Void> {
        tokenizer.eat(.id("fix"))
        tokenizer.eat(.lparen)

        var names: [Variable] = []
        var bindings: [Expr<Void>] = []

        while tokenizer.peek() == .success(.lparen) {
            tokenizer.eat(.lparen)
            let f = try parseVar()
            tokenizer.eat(.lparen)
            let vars = try parseVars()
            tokenizer.eat(.rparen)
            let body = try parseExpr()
            names.append(f)
            bindings.append(.abs(Lambda(vars: vars, body: body), ()))
            tokenizer.eat(.rparen)
        }

        tokenizer.eat(.rparen)
        let body = try parseExpr()

        return .fix2(names, names.map { _ in () }, bindings, body, ())
    }

    mutating func parseLetrec() throws -> Expr<Void> {
        tokenizer.eat(.id("letrec"))
        tokenizer.eat(.lparen)

        var vars: [Variable] = []
        var bindings: [Expr<Void>] = []

        while tokenizer.peek() == .success(.lparen) {
            tokenizer.eat(.lparen)
            vars.append(try parseVar())
            bindings.append(try parseExpr())
            tokenizer.eat(.rparen)
        }

        tokenizer.eat(.rparen)
        let body = try parseExpr()

        return .letrec(vars, bindings, body, ())
    }

    mutating func parseLambda() throws -> Expr<Void> {
        //tokenizer.eat(.lparen)  // lparen
        tokenizer.eat(.id("lambda"))  // lambda
        tokenizer.eat(.lparen)
        let vars = try parseVars()
        tokenizer.eat(.rparen)
        let body = try parseExpr()
        //tokenizer.eat(.rparen)
        return .abs(Lambda(vars: vars, body: body), ())
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

//
//  FixLetrec.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-09.
//

import Foundation

public extension Expr where Tag == Void {
    func fixLetrec() -> Expr {
        switch self {
        case .lit, .var:
            return self
        case let .abs(vars, body, tag):
            return .abs(vars, body.fixLetrec(), tag)
        case let .app(fn, args, tag):
            return .app(fn.fixLetrec(), args.map { $0.fixLetrec() }, tag)
        case let .let(vars, bindings, body, ()):
            return .let(vars, bindings, body, ())
        case let .cond(test, then, else_, ()):
            return .cond(test.fixLetrec(), then.fixLetrec(), else_.fixLetrec(), ())
        case let .seq(exprs, ()):
            return .seq(exprs.map { $0.fixLetrec() }, ())
        case let .letrec(vars, bindings, body, ()):
            var simple: [Expr] = []
            var lambda: [Expr] = []

            for (v, binding) in zip(vars, bindings) {
                switch binding {
                case let .abs(params, b, ()):
                    let e = Expr.let([v], [.fix(v, params, b, (), ())], body, ())
                    lambda.append(e)
                    assert(lambda.count == 1)
                default:
                    fatalError()
                }
            }
            // this is an atrocity...
            assert(simple.count == 0)
            return lambda.first!
        default:
            fatalError()
        }
    }
}

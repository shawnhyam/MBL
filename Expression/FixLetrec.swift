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
        case let .abs(lam, tag):
            return .abs(Lambda(vars: lam.vars, body: lam.body.fixLetrec()), tag)
        case let .app(fn, args, tag):
            return .app(fn.fixLetrec(), args.map { $0.fixLetrec() }, tag)
        case let .let(vars, bindings, body, ()):
            return .let(vars, bindings, body, ())
        case let .cond(test, then, else_, ()):
            return .cond(test.fixLetrec(), then.fixLetrec(), else_.fixLetrec(), ())
        case let .seq(exprs, ()):
            return .seq(exprs.map { $0.fixLetrec() }, ())
        case let .letrec(vars, bindings, body, ()):
            var simple: [(Variable, Expr)] = []
            var lambda: [(Variable, Expr)] = []

            for (v, binding) in zip(vars, bindings) {
                switch binding {
                case .abs:
                    lambda.append((v, binding))
                default:
                    simple.append((v, binding))
                }
            }
            // this is an atrocity...
            assert(simple.count == 0)
            return .fix2(lambda.map { $0.0 }, lambda.map { _ in () }, lambda.map { $0.1} , body, ())

        case let .fix2(vars, tags, exprs, body, ()):
            return .fix2(vars, tags, exprs.map { $0.fixLetrec() }, body.fixLetrec(), ())

        default:
            fatalError()
        }
    }
}

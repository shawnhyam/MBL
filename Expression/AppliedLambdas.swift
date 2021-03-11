//
//  AppliedLambdas.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-06.
//

import Foundation

public extension Expr where Tag == Void {
    func rewriteAppliedLambdas() -> Expr {
        switch self {
        case .lit, .var: return self
        case let .app(.abs(vars, body, ()), args, ()):
            return .let(vars, args.map { $0.rewriteAppliedLambdas() }, body.rewriteAppliedLambdas(), ())
        case let .abs(vars, body, ()):
            return .abs(vars, body.rewriteAppliedLambdas(), ())
        case let .app(fn, args, ()):
            return .app(fn.rewriteAppliedLambdas(), args.map { $0.rewriteAppliedLambdas() }, ())
        case let .let(vars, bindings, body, ()):
            return .let(vars, bindings.map { $0.rewriteAppliedLambdas() }, body.rewriteAppliedLambdas(), ())
        case let .letrec(vars, bindings, body, ()):
            return .letrec(vars, bindings.map { $0.rewriteAppliedLambdas() }, body.rewriteAppliedLambdas(), ())
        case let .cond(test, then, else_, ()):
            return .cond(test.rewriteAppliedLambdas(),
                         then.rewriteAppliedLambdas(),
                         else_.rewriteAppliedLambdas(),
                         ())
        case let .seq(exprs, ()):
            return .seq(exprs.map { $0.rewriteAppliedLambdas() }, ())
        default:
            fatalError()
        }
    }
}

//
//  TailCall.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-05.
//

import Foundation

public extension Expr where Tag == Void {
    func rewriteLet() -> Expr {
        switch self {
        case .lit, .var:
            return self
        case let .abs(vars, body, tag):
            return .abs(vars, body.rewriteLet(), tag)
        case let .app(fn, args, tag):
            return .app(fn.rewriteLet(), args.map { $0.rewriteLet() }, tag)
        case let .let(vars, bindings, body, ()):
            return Expr.app(.abs(vars, body, ()), bindings, ())
        case let .cond(test, then, else_, ()):
            return .cond(test.rewriteLet(), then.rewriteLet(), else_.rewriteLet(), ())
        case let .seq(exprs, ()):
            return .seq(exprs.map { $0.rewriteLet() }, ())
        default:
            fatalError()
        }
    }
}

public extension Expr {

    func findTailCalls(nextReturn: (abs: Tag, stack: Int)? = nil) -> [(app: Tag, abs: Tag, stack: Int)] {
        switch self {
        case .lit(_, _):
            return []
        case .var(_, _):
            return []
        case let .cond(test, then, else_, _):
            return test.findTailCalls() + then.findTailCalls() + else_.findTailCalls(nextReturn: nextReturn)
        case let .abs(vars, body, tag):
            return body.findTailCalls(nextReturn: (abs: tag, stack: vars.count))
        case .set(_, _, _):
            fatalError()
        case let .app(fn, args, tag):
            let result = args.flatMap { $0.findTailCalls(nextReturn: nil) } +
                fn.findTailCalls(nextReturn: nil)

            if let nextReturn = nextReturn {
                return result + [(app: tag, abs: nextReturn.0, stack: nextReturn.1)]
            } else {
                return result
            }
        case let .let(_, bindings, body, _):
            fatalError()
        case .fix(_, _, _, _, _):
            fatalError()
        case let .seq(exprs, _):
            if let expr = exprs.last {
                return expr.findTailCalls(nextReturn: nextReturn) + exprs.dropLast().flatMap { $0.findTailCalls() }
            } else {
                return []
            }
        }
    }
}

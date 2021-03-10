//
//  FindFree.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-06.
//

import Foundation

public extension Expr {
    func findFree(_ bound: Set<Variable>) -> Set<Variable> {
        switch self {
        case .lit(_, _):
            return []
        case let .var(v, _):
            return bound.contains(v) ? [] : [v]
        case let .cond(test, then, else_, _):
            return test.findFree(bound).union(then.findFree(bound)).union(else_.findFree(bound))
        case let .abs(vars, body, _):
            return body.findFree(bound.union(vars))
        case .set(_, _, _):
            fatalError()
        case let .app(fn, args, _):
            return fn.findFree(bound).union(args.reduce(Set()) { acc, arg in acc.union(arg.findFree(bound)) })
        case .let(_, _, _, _):
            fatalError()
        case .letrec(_, _, _, _):
            fatalError()
        case .seq(_, _):
            fatalError()
        case let .fix(f, vars, body, _, _):
            return body.findFree(bound.union(vars + [f]))
        }
    }

}

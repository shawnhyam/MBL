//
//  Expr.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

typealias Variable = String

indirect enum Expr<Tag> {
    case lit(Value, Tag)
    case `var`(Variable, Tag)
    case cond(Expr, Expr, Expr, Tag)
    case abs([Variable], Expr, Tag)
    case set(Variable, Expr, Tag)
    case app(Expr, [Expr], Tag)
    case `let`(Variable, Expr, Expr, Tag)
    case seq([Expr], Tag)
}

extension Expr {
    var tag: Tag {
        switch self {
        case let .lit(_, t):
            return t
        case let .var(_, t):
            return t
        case let .cond(_, _, _, t):
            return t
        case let .abs(_, _, t):
            return t
        case let .set(_, _, t):
            return t
        case let .app(_, _, t):
            return t
        case let .let(_, _, _, t):
            return t
        case let .seq(_, t):
            return t
        }
    }
    
    func untag() -> Expr<Void> {
        switch self {
        case let .lit(v, _):
            return .lit(v, ())
        case let .var(v, _):
            return .var(v, ())
        case let .cond(test, then, else_, _):
            return .cond(test.untag(), then.untag(), else_.untag(), ())
        case let .abs(vars, body, _):
            return .abs(vars, body.untag(), ())
        case let .set(v, expr, _):
            return .set(v, expr.untag(), ())
        case let .app(fn, args, _):
            return .app(fn.untag(), args.map { $0.untag() }, ())
        case let .let(v, binding, body, _):
            return .let(v, binding.untag(), body.untag(), ())
        case let .seq(exprs, _):
            return .seq(exprs.map { $0.untag() }, ())

        }
    }
}

extension Expr where Tag == Void {
    private func _tag(_ n: inout Int) -> Expr<Int> {
        defer { n += 1 }
        switch self {
        case let .lit(v, ()):
            return .lit(v, n)
        case let .var(v, ()):
            return .var(v, n)
        case let .cond(test, then, else_, ()):
            return .cond(test._tag(&n), then._tag(&n), else_._tag(&n), n)
        case let .abs(vars, body, ()):
            return .abs(vars, body._tag(&n), n)
        case let .set(v, expr, ()):
            return .set(v, expr._tag(&n), n)
        case let .app(fn, args, ()):
            return .app(fn._tag(&n), args.map { $0._tag(&n) }, n)
        case let .let(v, binding, body, ()):
            return .let(v, binding._tag(&n), body._tag(&n), n)
        case let .seq(exprs, ()):
            return .seq(exprs.map { $0._tag(&n) }, n)
        }
    }
    
    func applyTags() -> Expr<Int> {
        var n = 0
        return _tag(&n)
    }
}
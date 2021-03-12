//
//  EscapingClosures.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-06.
//

import Foundation

public extension Expr where Tag: Hashable {
    // TODO *also* need to detect whether there are any free variables in the closure;
    // if there aren't, then this is still okay because it's just a function pointer
    func findEscapingClosures(_ types: [Tag: Type]) -> [Tag] {
        let esc: [Tag]
        switch types[tag]! {
        case .arrow:
            esc = [tag]
        default:
            esc = []
        }

        switch self {
        case .var, .lit: return []
        case let .abs(lam, _):
            return esc + lam.body.findEscapingClosures(types)

        case let .let(_, bindings, body, _):
            return esc + bindings.flatMap { $0.findEscapingClosures(types) } + body.findEscapingClosures(types)

        case let .app(fn, args, _):
            return esc + fn.findEscapingClosures(types) + args.flatMap { $0.findEscapingClosures(types) }

        case let .cond(test, then, else_, _):
            return esc +
                test.findEscapingClosures(types) +
                then.findEscapingClosures(types) +
                else_.findEscapingClosures(types)

        case let .seq(exprs, _):
            return esc + exprs.flatMap { $0.findEscapingClosures(types) }

        case let .fix(_, _, body, _, _):
            return esc + body.findEscapingClosures(types)

        case let .fix2:
            // TODO
            return []

        default:
            fatalError()
        }
    }
}

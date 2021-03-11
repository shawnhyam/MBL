//
//  Rename.swift
//  Expression
//
//  Created by Shawn Hyam on 2021-03-06.
//

import Foundation

public extension Expr {
    func renameVariables() -> Expr {
        var n = 0
        return renameVariables(Env(), &n)
    }

}

private extension Expr {
    struct Env {
        var frames: [[String: String]] = []
        func rename(_ name: String) -> String {
            for frame in frames.reversed() {
                if let renamed = frame[name] {
                    return renamed
                }
            }
            return name  // must be a global?
        }
    }

    func renameVariables(_ env: Env, _ n: inout Int) -> Expr {
        switch self {
        case .lit: return self
        case let .var(name, tag):
            return .var(env.rename(name), tag)
        case let .abs(vars, body, tag):
            var env_ = env
            var frame = [String: String]()
            for v in vars {
                frame[v] = "\(v).\(n)"
                n += 1
            }
            env_.frames.append(frame)
            return .abs(vars.map { frame[$0]! }, body.renameVariables(env_, &n), tag)

        case let .app(fn, args, tag):
            return .app(fn.renameVariables(env, &n), args.map { $0.renameVariables(env, &n) }, tag)

        case let .let(vars, bindings, body, tag):
            var env_ = env
            var frame = [String: String]()
            for v in vars {
                frame[v] = "\(v).\(n)"
                n += 1
            }
            env_.frames.append(frame)
            return .let(vars.map { frame[$0]! },
                        bindings.map { $0.renameVariables(env, &n) },
                        body.renameVariables(env_, &n),
                        tag)

        case let .letrec(vars, bindings, body, tag):
            var env_ = env
            var frame = [String: String]()
            for v in vars {
                frame[v] = "\(v).\(n)"
                n += 1
            }
            env_.frames.append(frame)
            return .letrec(vars.map { frame[$0]! },
                           bindings.map { $0.renameVariables(env_, &n) },
                           body.renameVariables(env_, &n),
                           tag)

        case let .cond(test, then, else_, tag):
            return .cond(test.renameVariables(env, &n),
                         then.renameVariables(env, &n),
                         else_.renameVariables(env, &n),
                         tag)

        case let .seq(exprs, tag):
            return .seq(exprs.map { $0.renameVariables(env, &n) }, tag)
        default:
            fatalError()
        }
    }
}

//
//  ExprVM.swift
//  ExpressionVM
//
//  Created by Shawn Hyam on 2021-03-04.
//

import Foundation
import Expression

@propertyWrapper
public final class Box<T> {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}


public enum Value {
    case int(Int)
    case bool(Bool)
    case lambda([Variable], Expr<Int>, ExprVM.Env)
    case prim0(() -> Value)
    case prim2((Value, Value) -> Value)
}

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case let (.int(a), .int(b)): return a == b
        case let (.bool(a), .bool(b)): return a == b
        default:
            return false
        }
    }
}

extension Value: ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }

    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

public enum ExprVM {}

public extension ExprVM {
    typealias Env = [[Variable: Box<Value>]]

    static let globalEnv: Env = [
        [
            "time": Box(wrappedValue: .prim0 {
                return .int(0)
            }),
            "-": Box(wrappedValue: .prim2({ x, y in
                guard case let .int(arg0) = x, case let .int(arg1) = y else { fatalError() }
                return .int(arg0 - arg1)
            })),
            "*": Box(wrappedValue: .prim2({ x, y in
                guard case let .int(arg0) = x, case let .int(arg1) = y else { fatalError() }
                return .int(arg0 * arg1)
            })),
            "=": Box(wrappedValue: .prim2({ x, y in
                switch (x, y) {
                case let (.int(arg0), .int(arg1)): return .bool(arg0 == arg1)
                case let (.bool(arg0), .bool(arg1)): return .bool(arg0 == arg1)
                default: fatalError()
                }
            })),

        ]
    ]

    static func eval(_ expr: Expr<Int>, _ env: Env = Self.globalEnv) -> Value {
        switch expr {
        case let .lit(.int(v), _):
            return .int(v)
        case let .lit(.bool(v), _):
            return .bool(v)

        case let .app(fn, args, _):
            let fnVal = eval(fn, env)
            let argVals = args.map { eval($0, env) }
            return apply(fnVal, argVals)

        case let .abs(vars, body, _):
            return .lambda(vars, body, env)

        case let .var(name, _):
            for frame in env.reversed() {
                if let value = frame[name] {
                    return value.wrappedValue
                }
            }
            fatalError()

        case let .let(vars, bindings, body, _):
            assert(vars.count ==  bindings.count)
            var frame = [Variable: Box<Value>]()
            for (v, binding) in zip(vars, bindings) {
                frame[v] = Box(wrappedValue: eval(binding, env))
            }
            var env_ = env
            env_.append(frame)
            return eval(body, env_)

        case let .cond(test, then, else_, _):
            guard case let .bool(value) = eval(test, env) else { fatalError() }
            if value {
                return eval(then, env)
            } else {
                return eval(else_, env)
            }

        case let .seq(exprs, _):
            var result: Value!
            for expr in exprs {
                result = eval(expr, env)
            }
            return result

        case let .fix(f, vars, body, _, _):
            let frame: [Variable: Box<Value>] = [f: Box(wrappedValue: 0)]
            var env_ = env
            env_.append(frame)

            let lambda = Value.lambda(vars, body, env_)
            frame[f]?.wrappedValue = lambda
            return lambda

        default:
            fatalError()
        }
    }

    static func apply(_ fn: Value, _ args: [Value]) -> Value {
        switch fn {
        case let .lambda(vars, body, env):
            assert(args.count == vars.count)
            var frame = [Variable: Box<Value>]()
            for (v, arg) in zip(vars, args) {
                frame[v] = Box(wrappedValue: arg)
            }
            var env_ = env
            env_.append(frame)
            return eval(body, env_)
        case let .prim0(fn):
            assert(args.count == 0)
            return fn()
        case let .prim2(fn):
            assert(args.count == 2)
            return fn(args[0], args[1])
        default:
            fatalError()
        }
    }
}

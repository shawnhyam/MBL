//
//  Compile.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation
import Expression


public struct CompileEnv {
    public static let globals = [
        ("-", Value.prim2(.sub)),
        ("=", .eq) ,
        ("time", .time),
        ("*", .prim2(.mul))
    ]

    private(set) var globals: [String]
    private(set) var locals: [String] = []
    private(set) var temporaries: [String] = []
    private(set) var free: [String] = []
    private(set) var constants: [String: Value] = [:]

    public init() {
        self.globals = Self.globals.map { $0.0 }
    }

    public func frame(locals: [String], free: [String]) -> CompileEnv {
        var env_ = self
        env_.locals = locals
        env_.temporaries = []
        env_.free = free
        return env_
    }

    public func extend(_ v: String) -> CompileEnv {
        var env_ = self
        env_.temporaries.append(v)
        return env_
    }

    public func extend(_ name: String, _ value: Value) -> CompileEnv {
        var env_ = self
        env_.constants[name] = value
        return env_
    }
}

struct CompileContext {
    var dropReturn: Set<Int> = []
    var tailCall: [Int: Int] = [:]
    var escapingClosures: Set<Int> = []
}

extension Expr where Tag == Int {
    
    func collectFree(_ vars: [Variable], _ env: CompileEnv) -> [Inst] {
        return vars.flatMap { v in
            [compileRefer(v, env), .argument]
        }
    }

    
    func compileRefer(_ name: String, _ env: CompileEnv) -> Inst {
        if let idx = env.locals.firstIndex(of: name) {
            return .referLocal(idx, name)
        } else if let idx = env.temporaries.firstIndex(of: name) {
            return .referLocal(-idx-1, name)
        } else if let idx = env.free.firstIndex(of: name) {
            return .referFree(idx, name)
        } else if let idx = env.globals.firstIndex(of: name) {
            return .referGlobal(idx)
        } else if let value = env.constants[name] {
            return .constant(value)
        } else {
            fatalError()
        }
    }

    public func compile(_ env: CompileEnv) -> [Inst] {
        var inf = Inferencer()
        let types = inf.inferAll(self)

        var context = CompileContext()
        for tailCall in findTailCalls() {
            context.dropReturn.insert(tailCall.abs)
            context.tailCall[tailCall.app] = tailCall.stack
        }
        context.escapingClosures = Set(findEscapingClosures(types))

        var blocks: [Label: [Inst]] = [:]
        var main = _compile(context, env, &blocks) + [.halt]

        // collect up the addresses of the other code blocks
        var addresses: [Label: Int] = [:]
        for (label, block) in blocks {
            addresses[label] = main.count
            main.append(contentsOf: block)
        }

        // rewrite all labels to code addresses
        return main.map { inst in
            switch inst {
            case let .close(x, addr: .label(label)):
                return .close(x, addr: .abs(addresses[label]!))
            case let .constant(.closure(closure)):
                guard case let .label(label) = closure.body else { fatalError() }
                let addr = addresses[label]!
                return .constant(.closure(Closure(body: .abs(addr), values: closure.values)))
            default:
                return inst
            }
        }
    }
    
    func _compile(_ context: CompileContext,
                  _ env: CompileEnv,
                  _ blocks: inout [Label: [Inst]]) -> [Inst] {
        switch self {
        case let .lit(.int(v), _):
            return [.constant(.int(v))]
        case let .lit(.bool(v), _):
            return [.constant(.bool(v))]
        case let .var(name, _):
            return [compileRefer(name, env)]

        case let .abs(lam, tag):
            let free = Array(lam.body.findFree(Set(lam.vars).union(env.globals)))
            let env_ = env.frame(locals: lam.vars, free: free)

            let bodyC = lam.body._compile(context, env_, &blocks) +
                (context.dropReturn.contains(tag) ? [] : [.pop(lam.vars.count), .return])

            let tmp = collectFree(free, env)
            let insts = [Inst.close(free.count, addr: .label(lam.body.tag))]

//            if free.count > 0 && context.escapingClosures.contains(tag) {
//                fatalError("Right now we don't allow returning closures that capture values")
//            }

            blocks[lam.body.tag] = bodyC
            return tmp + insts

        case let .app(fn, args, tag):
            let tailCall = context.tailCall[tag]
            var insts: [Inst] = []

            args.reversed().forEach { arg in
                let argC = arg._compile(context, env, &blocks)
                insts.append(contentsOf: argC)
                insts.append(.argument)
            }

            insts.append(contentsOf: fn._compile(context, env, &blocks))

            if let stack = tailCall {
                return insts + [.shift(args.count, stack), .apply]
            } else {
                return [.frame(addr: .rel(insts.count+2))] + insts + [.apply]
            }

        case let .let(names, bindings, body, _):
            assert(names.count == bindings.count)
            // we are going to extend the current frame with more locals
            var code: [Inst] = []
            var env_ = env
            for (name, binding) in zip(names, bindings) {
                env_ = env_.extend(name)
                code.append(contentsOf: binding._compile(context, env_, &blocks))
                code.append(.argument)
            }

            code.append(contentsOf: body._compile(context, env_, &blocks))
            code.append(.pop(names.count))
            return code

        case .letrec:
            fatalError()
            
        case let .cond(pred, then, else_, _):
            let elseC = else_._compile(context, env, &blocks)
            let thenC = then._compile(context, env, &blocks) + [.jmp(addr: .rel(elseC.count+1))]
            let predC = pred._compile(context, env, &blocks) + [.test(addr: .rel(thenC.count+1))]
            return predC + thenC + elseC

        case let .seq(exprs, _):
            return exprs.flatMap { $0._compile(context, env, &blocks) }

        case let .fix(f, vars, body, t1, t2):
//            let allVars = vars
//            let free = Array(body.findFree(Set(allVars).union(env.globals).union([f])))
//            let recurse = Closure(body: .label(body.tag), values: [])
//            let env_ = CompileEnv(locals: allVars, free: free, constant: [f: .closure(recurse)])
//
//            let bodyC = body._compile(context, env_, &blocks) + [.pop(allVars.count), .return]
//
//            let tmp = collectFree(free, env_)
//            let insts = [Inst.close(free.count, addr: .label(body.tag))]
//
//            blocks[body.tag] = bodyC
//            return tmp + insts
            fatalError()

        case .set(_, _, _):
            fatalError()

        case let .fix2(fs, _, bindings, body, tag):
            let bound = Set(fs).union(env.globals)

            var code: [Inst] = []

            // extend the environment with the recursive functions
            var env_ = env
            for (f, binding) in zip(fs, bindings) {
                guard case let .abs(lambda, _) = binding else { fatalError() }
                let free = Array(lambda.body.findFree(Set(lambda.vars).union(env_.globals).union(fs)))
                env_ = env.extend(f)
                let tmp = collectFree(free, env_)
                let insts = [Inst.close(free.count, addr: .label(lambda.body.tag))]
                code.append(contentsOf: tmp + insts)
                code.append(.argument)
            }

            for (f, binding) in zip(fs, bindings) {
                guard case let .abs(lambda, _) = binding else { fatalError() }

                let free = Array(lambda.body.findFree(Set(lambda.vars).union(env_.globals).union([f])))
                var env_ = env_.frame(locals: lambda.vars, free: free)
                env_ = env_.extend(f, .closure(Closure(body: .label(lambda.body.tag), values: [])))


                let bodyC = lambda.body._compile(context, env_, &blocks) +
                    (context.dropReturn.contains(tag) ? [] : [.pop(lambda.vars.count), .return])

                blocks[lambda.body.tag] = bodyC
            }

            code.append(contentsOf: body._compile(context, env_, &blocks))
            code.append(.pop(fs.count))
            return code


//            // create the closures for each recursive function
//            for (f, binding) in zip(fs, bindings) {
//                guard case let .abs(lambda, _) = binding else { fatalError() }
//                // TODO gather free variables?
//                let free = Array(lambda.body.findFree(Set(lambda.vars).union(env.globals).union(fs)))
//                //let recur = Closure(body: .label(body.tag), values: free)
//
//            }
//
//            for binding in bindings {
//                let recur = Closure(body: .label(body.tag), values: [])
//                let env_ = CompileEnv(local: lambda.vars, free: free, constant: [f: .closure(recur)])
//                guard case let .abs(lambda, _) = binding else { fatalError() }
//                // FIXME should check and see if there are any free variables to collect?
//                let bodyC = body._compile(context, env_, &blocks) + [.pop(allVars.count), .return]
//
//            }
//
            return []

        default:
            fatalError()
        }
    }
}


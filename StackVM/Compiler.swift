//
//  Compile.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation
import Expression


let globals = Set<Variable>(arrayLiteral: "-", "=", "time")

public struct CompileEnv {
    var global: [String]
    var local: [String]
    var free: [String]

    public init(global: [String] = ["-", "=", "time"],
                local: [String] = [],
                free: [String] = []) {
        self.global = global
        self.local = local
        self.free = free
    }
}

struct CompileContext {
    var dropReturn: Set<Int> = []
    var tailCall: [Int: Int] = [:]
}

extension Expr where Tag == Int {
    func findFree(_ bound: Set<Variable>) -> Set<Variable> {
        switch self {
        case .lit(_, _):
            return []
        case let .var(v, _):
            if globals.contains(v) { return [] }
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
        case .seq(_, _):
            fatalError()
        case let .fix(f, vars, body, _, _):
            return body.findFree(bound.union(vars + [f]))
        }
    }
    
    func collectFree(_ vars: [Variable], _ env: CompileEnv) -> [Inst] {
        return vars.flatMap { v in
            [compileRefer(v, env), .argument]
        }
    }

    
    func compileRefer(_ name: String, _ env: CompileEnv) -> Inst {
        if let idx = env.local.firstIndex(of: name) {
            return .referLocal(idx, name)
        } else if let idx = env.free.firstIndex(of: name) {
            return .referFree(idx)
        } else if let idx = env.global.firstIndex(of: name) {
            return .referGlobal(idx)
        } else {
            fatalError()
        }
    }

    public func compile(_ env: CompileEnv) -> [Inst] {
        var context = CompileContext()
        for tailCall in findTailCalls() {
            context.dropReturn.insert(tailCall.abs)
            context.tailCall[tailCall.app] = tailCall.stack
        }

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

        case let .abs(vars, body, tag):
            let free = Array(body.findFree(Set(vars).union(globals)))
            let env_ = CompileEnv(local: vars, free: free)

            let bodyC = body._compile(context, env_, &blocks) +
                (context.dropReturn.contains(tag) ? [] : [.return(vars.count)])

            let tmp = collectFree(free, env)
            let insts = [Inst.close(free.count, addr: .label(body.tag))]

            blocks[body.tag] = bodyC
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

        case let .let(names, bindings, body, tag):
            // inefficient, but rewrite let into lambda and apply
            //return Expr.app(.abs(names, body, tag), bindings, tag)._compile(context, env, &blocks)
            fatalError()


        case let .cond(pred, then, else_, _):
            let elseC = else_._compile(context, env, &blocks)
            let thenC = then._compile(context, env, &blocks) + [.jmp(addr: .rel(elseC.count+1))]
            let predC = pred._compile(context, env, &blocks) + [.test(addr: .rel(thenC.count+1))]
            return predC + thenC + elseC

        case let .seq(exprs, _):
            return exprs.flatMap { $0._compile(context, env, &blocks) }

        case let .fix(f, vars, body, _, _):
            let allVars = vars
            let free = Array(body.findFree(Set(allVars).union(globals)))
            let env_ = CompileEnv(local: allVars, free: free)

            let bodyC = body._compile(context, env_, &blocks) + [.return(allVars.count)]

            let tmp = collectFree(free, env_)
            let insts = [Inst.close(free.count, addr: .label(body.tag))]

            blocks[body.tag] = bodyC
            return tmp + insts


            fatalError()
//            var bodyC: [Inst] = [.return(vars.count)]
//            body.compile(env_, &bodyC)
//
//            let offset = program.count+1
//            program.insert(contentsOf: bodyC, at: 0)
//
//            program.append(.close(free.count, addr: offset))
//
//            let tmp = collectFree(free, env)
//            program.append(contentsOf: tmp)
        case .set(_, _, _):
            fatalError()
        }
    }
}


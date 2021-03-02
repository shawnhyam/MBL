//
//  Compile.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation


let globals = Set<Variable>(arrayLiteral: "-", "=", "time")

struct CompileEnv {
    var global: [String] = ["-", "=", "time"]
    var local: [String] = []
    var free: [String] = []
}


extension Expr {
    func findFree(_ bound: Set<Variable>) -> Set<Variable> {
        switch self {
        case .lit(_, _):
            return []
        case let .var(v, _):
            if globals.contains(v) { return [] }
            return bound.contains(v) ? [] : [v]
        case .cond(_, _, _, _):
            fatalError()
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
        }
    }
    
    func collectFree(_ vars: [Variable], _ env: CompileEnv) -> [Inst] {
        return vars.flatMap { v in
            [.argument, compileRefer(v, env)]
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

    func compile(_ env: CompileEnv) -> [Inst] {
        var program: [Inst] = [.halt]
        compile(env, &program)
        return program.reversed()
    }
    
    func _compile(_ env: CompileEnv) -> [Inst] {
        var program: [Inst] = []
        compile(env, &program)
        return program
    }

    func compile(_ env: CompileEnv, _ program: inout [Inst]) {
        switch self {
        case let .lit(v, _):
            program.append(.constant(v))
        case let .var(name, _):
            program.append(compileRefer(name, env))
            
        case let .let(names, bindings, body, tag):
            // inefficient, but rewrite let into lambda and apply
            Expr.app(.abs(names, body, tag), bindings, tag).compile(env, &program)

        case let .abs(vars, body, _):
            let free = Array(body.findFree(Set(vars).union(globals)))
            let env_ = CompileEnv(local: vars, free: free)
            
            var bodyC: [Inst] = [.return(vars.count)]
            body.compile(env_, &bodyC)

            let offset = program.count+1
            program.insert(contentsOf: bodyC, at: 0)
            
            program.append(.close(free.count, addr: offset))

            let tmp = collectFree(free, env)
            program.append(contentsOf: tmp)
        
        case let .app(fn, args, _):
            let tailCall: Bool
            var offset = 1
            
            //let fnC: Inst
            if case let .return(m) = program.last { //, args.count != m {
                tailCall = true
                program.removeLast()
                
                var fnC: [Inst] = [.apply, .shift(args.count, m)]
                fn.compile(env, &fnC)
                program.append(contentsOf: fnC)
                offset += fnC.count - 1  // because we removed the ret

                //fnC = fn.compileYYZ(env, .shift(args.count, m, .apply))
            } else {
                tailCall = false
                var fnC: [Inst] = [.apply]
                fn.compile(env, &fnC)
                program.append(contentsOf: fnC)
                offset += fnC.count
            }
            
            var argsC: [Inst] = []
            args.forEach { arg in
                argsC.append(.argument)
                arg.compile(env, &argsC)
            }
            program.append(contentsOf: argsC)
            offset += argsC.count
            
            if tailCall {
                // don't create a new frame
            } else {
                program.append(.frame(addr: offset))
            }
            
        case let .cond(pred, then, else_, _):
            //Inst.test(<#T##CodeAddr#>)
            let elseC = else_._compile(env)
            let thenC = [.jmp(addr: elseC.count+1)] + then._compile(env)
            let predC = [.test(addr: thenC.count+1)] + pred._compile(env)
            
            // predC, test, thenC, jmp, elseC, ...
            program.append(contentsOf: elseC)
            program.append(contentsOf: thenC)
            program.append(contentsOf: predC)
        
            
        case .set(_, _, _):
            fatalError()
            
        case let .seq(exprs, _):
            let inst = exprs.reversed().flatMap { $0._compile(env) }
            program.append(contentsOf: inst)
        }
    }
}


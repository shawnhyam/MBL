//
//  Compiler.swift
//  ForthVM
//
//  Created by Shawn Hyam on 2021-03-06.
//

import Foundation
import Expression

public typealias Value = UInt16
typealias Label = String

let globals = Set<Variable>(arrayLiteral: "-", "=", "time")

public struct CompileEnv {
    var dStack: [String] = []

    var global: [String]
    var local: [String]
    var temp: [String]
    var free: [String]
    var constant: [String: Value]

    public init(global: [String] = ["-", "=", "time"],
                local: [String] = [],
                temp: [String] = [],
                free: [String] = [],
                constant: [String: Value] = [:]) {
        self.global = global
        self.local = local
        self.temp = temp
        self.free = free
        self.constant = constant
    }
}

struct CompileContext {
    var dropReturn: Set<Int> = []
    var tailCall: [Int: Int] = [:]
    var escapingClosures: Set<Int> = []
    var numReferences: [String: Int] = [:]
}

extension Expr {
    // count how many times a name is referred to... needed because reads are destructive
    func countReferences() -> [String] {
        switch self {
        case .lit: return []
        case let .var(name, _): return [name]
        case let .let(_, bindings, body, _):
            return bindings.flatMap { $0.countReferences() } + body.countReferences()
        case let .app(fn, args, _):
            return fn.countReferences() + args.flatMap { $0.countReferences() }
        case let .cond(test, then, else_, _):
            return test.countReferences() + then.countReferences() + else_.countReferences()

        default:
            fatalError()
        }
    }
}


extension Expr where Tag == Int {

    func compileRefer(_ name: String, _ n: Int, _ env: inout CompileEnv) -> [Inst] {
        if env.dStack.last == name {
            if env.dStack.filter { $0 == name }.count == 1 && n>0 {
                env.dStack.append(name)
                return [.dup]
            }
            env.dStack.removeLast()
            return []
        } else if env.dStack.dropLast().last == name {
            return [.swap]
        }



        if let idx = env.local.firstIndex(of: name) {
            fatalError()
            //return .referLocal(idx, name)
        } else if let idx = env.free.firstIndex(of: name) {
            fatalError()
            //return .referFree(idx)
        } else if let idx = env.global.firstIndex(of: name) {
            return [.addrOf(name)]
            //return .referGlobal(idx)
        } else if let idx = env.temp.firstIndex(of: name) {
            fatalError()
            //return .referTemp(idx, name)
        } else if let value = env.constant[name] {
            fatalError()
            //return .constant(value)
        } else {
            fatalError()
        }
    }

    public func compile(_ env: inout CompileEnv) -> [Int: [Inst]] {
        var inf = Inferencer()
        let types = inf.inferAll(self)

        var context = CompileContext()
        for tailCall in findTailCalls() {
            context.dropReturn.insert(tailCall.abs)
            context.tailCall[tailCall.app] = tailCall.stack
        }
        context.escapingClosures = Set(findEscapingClosures(types))
        for name in countReferences() {
            if var n = context.numReferences[name] {
                n += 1
                context.numReferences[name] = n
            } else {
                context.numReferences[name] = 1
            }
        }

        var blocks: [Label: [Inst]] = [
            "-": [.neg, .add, .ret],
            "=": [.ret],
        ]
        var main = _compile(&context, &env, &blocks) + [0x1337]
        var result: [Int: [Inst]] = [:]

        // collect up the addresses of the other code blocks
        var addresses: [Label: Int] = [:]
        var count = 0x0800
        for (label, block) in blocks {
            result[count] = block
            addresses[label] = count
            count += block.count
            //main.append(contentsOf: block)
        }

        // replace addrOf with actual addresses
        main = main.map { inst in
            guard case let .addrOf(label) = inst else { return inst }
            return .literal(UInt16(addresses[label]!))
        }

        // replace (literal, icall) with call instruction
        var i = 0
        var main_ = [Inst]()
        while i < main.count {
            let inst = main[i]
            guard i+1 < main.count else {
                main_.append(inst)
                i += 1
                continue
            }

            let next = main[i+1]

            switch (inst, next) {
            case let (.literal(n), .icall):
                main_.append(.call(n))
                i += 2
            default:
                main_.append(inst)
                i += 1
            }

        }
        result[0] = main_

        return result
    }

    func _compile(_ context: inout CompileContext,
                  _ env: inout CompileEnv,
                  _ blocks: inout [Label: [Inst]]) -> [Inst] {
        switch self {
        case let .lit(.int(v), _):
            assert(v >= 0 && v <= 0x7fff)
            return [.literal(UInt16(v))]

        case let .lit(.bool(b), _):
            return [.literal(b ? 1 : 0)]

        case let .var(name, _):
            var n = context.numReferences[name]!
            n -= 1
            context.numReferences[name] = n
            return compileRefer(name, n, &env)

        case let .let(names, bindings, body, _):
            assert(names.count == bindings.count)
            // we are going to extend the current frame with more locals
            var code: [Inst] = []

            // consider ordering the evaluation of the bindings based on whatever
            // would be best to evaluate the body
            for (name, binding) in zip(names, bindings).reversed() {
                env.temp.append(name)
                env.dStack.append(name)
                code.append(contentsOf: binding._compile(&context, &env, &blocks))
            }

            // maybe count up how much time each variable is used? if used only once,
            // we could keep it on the stack; but if used more times, maybe find a
            // random-access location for it

            // TODO random-access location for all of the names

            code.append(contentsOf: body._compile(&context, &env, &blocks))
            return code

        case let .app(fn, args, _):
            // evaluate args right-to-left, leaving their values on the parameter stack
            // in the correct order
            let argsC = args.reversed().flatMap { $0._compile(&context, &env, &blocks) }
            let fnC = fn._compile(&context, &env, &blocks)

            return argsC + fnC + [.icall]

        case let .cond(test, then, else_, _):
            let testC = test._compile(&context, &env, &blocks)
            let thenC = then._compile(&context, &env, &blocks)
            let elseC = else_._compile(&context, &env, &blocks)
            fatalError()

        default:
            fatalError()
        }
    }
}


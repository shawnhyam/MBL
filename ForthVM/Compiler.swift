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
}


extension Expr where Tag == Int {

    func compileRefer(_ name: String, _ env: inout CompileEnv) -> [Inst] {
        if env.dStack.last == name {
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
            fatalError()
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

    public func compile(_ env: inout CompileEnv) -> [Inst] {
        var inf = Inferencer()
        let types = inf.inferAll(self)

        var context = CompileContext()
        for tailCall in findTailCalls() {
            context.dropReturn.insert(tailCall.abs)
            context.tailCall[tailCall.app] = tailCall.stack
        }
        context.escapingClosures = Set(findEscapingClosures(types))

        var blocks: [Label: [Inst]] = [:]
        var main = _compile(context, &env, &blocks)

        // collect up the addresses of the other code blocks
        var addresses: [Label: Int] = [:]
        for (label, block) in blocks {
            addresses[label] = main.count
            main.append(contentsOf: block)
        }

        return main + [0x1000]
    }

    func _compile(_ context: CompileContext,
                  _ env: inout CompileEnv,
                  _ blocks: inout [Label: [Inst]]) -> [Inst] {
        switch self {
        case let .lit(.int(v), _):
            assert(v >= 0 && v <= 0x7fff)
            return [.literal(UInt16(v))]

        case let .var(name, _):
            if name == "-" {
                return [.addrOf("-")]
            } else {
                return compileRefer(name, &env)
            }

        case let .let(names, bindings, body, _):
            assert(names.count == bindings.count)
            // we are going to extend the current frame with more locals
            var code: [Inst] = []

            // consider ordering the evaluation of the bindings based on whatever
            // would be best to evaluate the body
            for (name, binding) in zip(names, bindings).reversed() {
                env.temp.append(name)
                env.dStack.append(name)
                code.append(contentsOf: binding._compile(context, &env, &blocks))
            }

            // maybe count up how much time each variable is used? if used only once,
            // we could keep it on the stack; but if used more times, maybe find a
            // random-access location for it

            // TODO random-access location for all of the names

            code.append(contentsOf: body._compile(context, &env, &blocks))
            return code

        case let .app(fn, args, _):
            // evaluate args right-to-left, leaving their values on the parameter stack
            // in the correct order
            let argsC = args.reversed().flatMap { $0._compile(context, &env, &blocks) }
            let fnC = fn._compile(context, &env, &blocks)

            switch fnC.last {
            case .addrOf("-"):
                return argsC + Inst.sub
            default:
                fatalError()

            }

        default:
            fatalError()
        }
    }
}


//
//  VM.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

public struct VM {
    let program: [Inst]
    var stack: Stack = Stack()

    public private(set) var acc: Value = .int(0)
    var next: Int = 0
    var fp: Int = 0
    var cl: Closure = .init(body: 0, values: [])
    var count = 0
    
    public init(program: [Inst]) {
        self.program = program

        for (inst1, inst2) in zip(program, program[1...]) {
            switch (inst1, inst2) {
            case (.apply, .return):
                fatalError()
            default:
                break
            }
            print(inst1, inst2)
        }
    }
    
    public mutating func step() -> Bool {
        let inst = program[next]
        print(next, fp, stack.tos, ":", inst)
        next += 1
        defer { count += 1 }
        
        switch inst {
        case .halt:
            return false
        case .argument:
            stack.push(acc)

        case let .referGlobal(idx):
            if idx == 0 {
                acc = .sub
            } else if idx == 1 {
                acc = .eq
            } else if idx == 2 {
                acc = .time
            } else {
                fatalError()
            }
        case let .referFree(idx):
            acc = cl.values[idx]
            
        case let .referLocal(idx, _):
            acc = stack[fp, idx]
        case let .constant(obj):
            acc = obj
        case let .close(freeLength, body):
            guard case let .abs(addr) = body else { fatalError() }
            acc = .closure(Closure(body: addr, values: (0..<freeLength).map { i in stack[stack.tos, i] }))
            stack.tos -= freeLength

        case let .frame(addr):
            guard case let .rel(addr) = addr else { fatalError() }
            stack.push(.closure(cl))
            stack.push(.stackAddr(fp))
            stack.push(.codeAddr(next+addr-1))

        case .apply:
            switch acc {
            case let .closure(closure):
                next = closure.body
                fp = stack.tos
                cl = closure
            case .sub:
                guard case let .int(arg0) = stack[stack.tos, 0],
                      case let .int(arg1) = stack[stack.tos, 1] else { fatalError() }
                acc = .int(arg0 - arg1)
                stack.tos -= 2
                guard case let .codeAddr(ret) = stack[stack.tos, 0],
                      case let .stackAddr(link) = stack[stack.tos, 1],
                      case let .closure(cl) = stack[stack.tos, 2] else { fatalError() }
                next = ret
                fp = link
                self.cl = cl
                stack.tos -= 3
            case .eq:
                let arg0 = stack[stack.tos, 0]
                let arg1 = stack[stack.tos, 1]
                switch (arg0, arg1) {
                case let (.int(v0), .int(v1)):
                    acc = .bool(v0 == v1)
                case let (.bool(v0), .bool(v1)):
                    acc = .bool(v0 == v1)
                default:
                    fatalError()
                }
                stack.tos -= 2
                guard case let .codeAddr(ret) = stack[stack.tos, 0],
                      case let .stackAddr(link) = stack[stack.tos, 1],
                      case let .closure(cl) = stack[stack.tos, 2] else { fatalError() }
                next = ret
                fp = link
                self.cl = cl
                stack.tos -= 3

            case .time:
                acc = .int(count)
                guard case let .codeAddr(ret) = stack[stack.tos, 0],
                      case let .stackAddr(link) = stack[stack.tos, 1],
                      case let .closure(cl) = stack[stack.tos, 2] else { fatalError() }
                next = ret
                fp = link
                self.cl = cl
                stack.tos -= 3

            default:
                fatalError()
            }


        case let .test(else_):
            guard case let .rel(addr) = else_ else { fatalError() }
            if acc.isFalse {
                next += addr - 1
            }
//        case .assign(_):
            /*
             Implementations for languages that support first-class functions and assignments but not continuations (such as Common Lisp) can benefit from this optimization; the criteria for creating boxes is not only that a variable is assigned but also that it occurs free in some function for which a closure might be created.
             */
//            fatalError()

        case let .shift(n, m):
            stack.shift(n, m)

        case let .jmp(addr):
            guard case let .rel(addr) = addr else { fatalError() }
            next = next+addr-1
        case let .return(n):
            stack.tos -= n
            guard case let .codeAddr(ret) = stack[stack.tos, 0],
                  case let .stackAddr(link) = stack[stack.tos, 1],
                  case let .closure(cl) = stack[stack.tos, 2] else { fatalError() }
            next = ret
            fp = link
            self.cl = cl
            stack.tos -= 3
        }
        return true
    }
}



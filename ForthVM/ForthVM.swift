//
//  ForthVM.swift
//  ForthVM
//
//  Created by Shawn Hyam on 2021-03-05.
//

import Foundation

/*
public enum Inst: Equatable {
    case shift(Int, Int)

    case halt
    case referGlobal(Int)  // could just be a constant instead?
    case referLocal(Int, String)
    case referTemp(Int, String)
    case referFree(Int)
    case constant(Value)
    case close(Int, addr: Addr) //CodeAddr)
    case test(addr: Addr) //CodeAddr)
    //case assign(Loc)
//    case conti(Label)
//    case nuate(Stack, Variable)
    case frame(addr: Addr)
    case argument
    case apply
    case pop(Int)
    case `return`
    case jmp(addr: Addr)
}
 */

public enum AluOp: UInt16 {
    case t = 0
    case n
    case add
    case and
    case or
    case xor
    case not
    case eq
    case gte
    case rshift
    case dec
    case r
    case fetch
    case lshift
    case depth
    case ugte
}

public struct AluInst {
    var op: AluOp
    var rToPC: Bool
    var tToN: Bool
    var tToR: Bool
    var nToAddrOfT: Bool
    var rStack: Int  // -1, 0, +1
    var dStack: Int  // -1, 0, +1

    var machineCode: UInt16 {
        var result: UInt16 = 0
        if rToPC { result |= 0x1000 }
        result |= (op.rawValue << 8)
        if tToN { result |= 0x80 }
        if tToR { result |= 0x40 }
        if nToAddrOfT { result |= 0x20 }
        if dStack == 1 {
            result |= 0x4
        } else if dStack == -1 {
            result |= 0x8
        }
        if rStack == 1 {
            result |= 0x1
        } else if rStack == -1 {
            result |= 0x2
        }

        return result
    }
}
extension AluInst {
    init(_ rawValue: UInt16) {
        rToPC = (rawValue & 0x1000) != 0
        op = AluOp(rawValue: (rawValue & 0x0f00) >> 8)!
        tToN = (rawValue & 0x80) != 0
        tToR = (rawValue & 0x40) != 0
        nToAddrOfT = (rawValue & 0x20) != 0
        switch (rawValue & 0xc) >> 2 {
        case 0: dStack = 0
        case 1: dStack = 1
        case 2: dStack = -1
        default: fatalError()
        }
        switch (rawValue & 0x3) {
        case 0: rStack = 0
        case 1: rStack = 1
        case 2: rStack = -1
        default: fatalError()
        }

    }
}

public enum Inst {
    case literal(UInt16)
    case jmp(UInt16)
    case cjmp(UInt16)
    case call(UInt16)
    case alu(AluInst)

    init(_ rawValue: UInt16) {
        if (rawValue & 0x8000) != 0 {
            self = .literal(rawValue & 0x7fff)
        } else if (rawValue & 0x6000) == 0x6000 {
            self = .alu(AluInst(rawValue))
        } else {
            fatalError()
        }
    }

    var machineCode: UInt16 {
        switch self {
        case let .literal(v):
            return 0x8000 | v
        case let .alu(aluInst):
            return 0x6000 | aluInst.machineCode
        default:
            fatalError()
        }
    }

    static var add = Inst.alu(.init(op: .add, rToPC: false, tToN: false, tToR: false, nToAddrOfT: false, rStack: 0, dStack: -1))

    static var sub: [Inst] = [.neg, .add]

    static var neg = Inst.alu(.init(op: .not, rToPC: false, tToN: false, tToR: false, nToAddrOfT: false, rStack: 0, dStack: 0))

    static var dup = Inst.alu(.init(op: .t, rToPC: false, tToN: true, tToR: false, nToAddrOfT: false, rStack: 0, dStack: 1))


    static var store = Inst.alu(.init(op: .n, rToPC: false, tToN: false, tToR: false, nToAddrOfT: true, rStack: 0, dStack: -1))

    static var fetch = Inst.alu(.init(op: .fetch, rToPC: false, tToN: false, tToR: false, nToAddrOfT: false, rStack: 0, dStack: 0))

    static var drop = Inst.alu(.init(op: .n, rToPC: false, tToN: false, tToR: false, nToAddrOfT: false, rStack: 0, dStack: -1))

}

extension Inst: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt16) {
        self = .literal(value & 0x7fff)
    }
}

public struct ForthVM {
    // consider Harvard architecture to reduce memory/bus contention
    var dStack: [UInt16] =  [] //.init(repeating: 0, count: 16)
    var rStack: [UInt16] = [] //.init(repeating: 0, count: 16)
    var mem: [UInt16] = .init(repeating: 0, count: 4096)
    var pc: UInt16 = 0
    //var d: Int = 0

    mutating func step() {
        let inst = Inst(mem[Int(pc)])
        pc += 1

        switch inst {
        case let .literal(l):
            dStack.append(l)
        case let .jmp(addr):
            pc = addr
        case let .cjmp(addr):
            let t = dStack.removeLast()
            if t == 0 {
                pc = addr
            }
        case let .call(addr):
            rStack.append(pc)
            pc = addr
        case let .alu(aluInst):
            let t = dStack.last ?? 0
            let n = dStack.dropLast().last ?? 0

            if aluInst.nToAddrOfT {
                mem[Int(t)] = n
            }

            let t_: UInt16
            switch aluInst.op {
            case .t: t_ = t
            case .n: t_ = n
            case .add: t_ = t &+ n
            case .not: t_ = ~t
            case .fetch: t_ = mem[Int(t)]
            default:
                fatalError()
            }


            switch aluInst.dStack {
            case 0: dStack[dStack.count-1] = t_
            case 1: dStack.append(t_)
            case -1:
                dStack.removeLast()
                if dStack.count > 0 {
                    dStack[dStack.count-1] = t_
                }
            default:
                fatalError()
            }


        default:
            fatalError()
        }

    }
}

//
//  Inst.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

public typealias Label = Int

public enum Addr: Equatable {
    case label(Label)
    case abs(Int)
    case rel(Int)
}

public enum Inst: Equatable {
    case shift(Int, Int)

    case halt
    case referGlobal(Int)  // could just be a constant instead?
    case referLocal(Int, String)
    case referTemp(Int, String)
    case referFree(Int, String)
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


extension Inst: CustomStringConvertible {
    public var description: String {
        switch self {
        case .halt: return "halt"
        case .shift: return "shift"
        case .referGlobal(_): return "gvar"
        case .referLocal(_, _): return "lvar"
        case .referTemp(_, _): return "tvar"
        case .referFree(_): return "fvar"
        case .constant(_): return "const"
        case let .close(count, addr): return "close(\(count)) -> \(addr)"
        case .test(_): return "test"
        //case .assign(_): return "set!"
        case let .frame(relAddr): return "frame -> \(relAddr)"
        case .argument: return "arg"
        case .apply: return "call"
        case .return: return "ret"
        case let .pop(n): return "pop(\(n))"
        case .jmp(_): return "jmp"
        }
    }
}

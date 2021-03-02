//
//  Inst.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

enum Inst: Equatable {
    case shift(Int, Int)

    case halt
    case referGlobal(Int)  // could just be a constant instead?
    case referLocal(Int, String)
    case referFree(Int)
    case constant(Value)
    case close(Int, addr: Int) //CodeAddr)
    case test(addr: Int) //CodeAddr)
    //case assign(Loc)
//    case conti(Label)
//    case nuate(Stack, Variable)
    case frame(addr: Int)
    case argument
    case apply
    case `return`(Int)
    case jmp(addr: Int)
}


extension Inst: CustomStringConvertible {
    var description: String {
        switch self {
        case .halt: return "halt"
        case .shift: return "shift"
        case .referGlobal(_): return "gvar"
        case .referLocal(_, _): return "lvar"
        case .referFree(_): return "fvar"
        case .constant(_): return "const"
        case let .close(count, addr): return "close(\(count)) -> \(addr)"
        case .test(_): return "test"
        //case .assign(_): return "set!"
        case let .frame(addr): return "frame -> \(addr)"
        case .argument: return "arg"
        case .apply: return "call"
        case .return(_): return "ret"
        case .jmp(_): return "jmp"
        }
    }
}

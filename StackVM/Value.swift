//
//  Value.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

public struct Closure: Equatable {
    var body: Addr
    var values: [Value]
    
    public init(body: Addr, values: [Value]) {
        self.body = body
        self.values = values
    }
}

public enum BinOp: Equatable {
    case sub
    case mul

    func run(_ arg0: Value, _ arg1: Value) -> Value {
        switch self {
        case .sub:
            guard case let .int(arg0) = arg0,
                  case let .int(arg1) = arg1 else { fatalError() }
            return .int(arg0 - arg1)

        case .mul:
            guard case let .int(arg0) = arg0,
                  case let .int(arg1) = arg1 else { fatalError() }
            return .int(arg0 * arg1)
        }
    }
}

public enum Value: Equatable {
    case stackAddr(Int)
    case codeAddr(Addr)
    case int(Int)
    case bool(Bool)
    case closure(Closure)
    case prim2(BinOp)
    case eq
    case time
    
    var isFalse: Bool {
        return self == .bool(false)
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

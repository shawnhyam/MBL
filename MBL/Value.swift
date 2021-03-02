//
//  Value.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

struct Closure: Equatable {
    var body: Int
    var values: [Value]
}

enum Value: Equatable {
    case stackAddr(Int)
    case codeAddr(Int)
    case int(Int)
    case bool(Bool)
    case closure(Closure)
    case sub
    case eq
    case time
    
    var isFalse: Bool {
        return self == .bool(false)
    }
}

extension Value: ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
    
    init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

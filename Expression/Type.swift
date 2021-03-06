//
//  Type.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation
import Tagged

public indirect enum Type: Equatable {
    public typealias Id = Tagged<Type, String>
    
    case `var`(Id)
    case int
    case bool
    case arrow([Type])
}


extension Type: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .var(id): return id.rawValue
        case .int: return "int"
        case .bool: return "bool"
        case let .arrow(types):
            return types.map { $0.description }.joined(separator: " -> ")
        }
    }
}

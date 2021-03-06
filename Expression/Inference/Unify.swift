//
//  Unify.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation
import Expression

extension Sequence {
    func anySatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try !allSatisfy { try !predicate($0) }
    }
}

// invariant for substitutions:
// no id on a lhs occurs in any term earlier in the list
typealias Substitution = [(Type.Id, Type)]

// check if a variable occurs in a term
func occurs(_ x: Type.Id, _ t: Type) -> Bool {
    switch t {
    case let .var(y): return x == y
    case .int, .bool: return false
    case let .arrow(s): return s.anySatisfy { occurs(x, $0) }
    }
}

// substitute term s for all occurences of variable x in term t
func subst(_ s: Type, _ x: Type.Id, _ t: Type) -> Type {
    switch t {
    case let .var(y):
        return x == y ? s : t
    case .int, .bool: return t
    case let .arrow(fs): return .arrow(fs.map { subst(s, x, $0) })
    }
}

// apply a substitution
func apply(_ s: Substitution, _ t: Type) -> Type {
    var tmp = t
    for sub in s.reversed() {
        tmp = subst(sub.1, sub.0, tmp)
    }
    return tmp
}

// unify one pair
func unifyOne(_ s: Type, _ t: Type) -> Substitution {
    switch (s, t) {
    case let (.var(x), .var(y)):
        return x == y ? [] : [(x, t)]
    case (_, .var(_)):
        return unifyOne(t, s)
    case let (.var(x), _):
        if occurs(x, t) {
            fatalError()
        } else {
            return [(x, t)]
        }
    case let (.arrow(f), .arrow(g)):
        return unify(Array(zip(f, g)))
    case (.int, .int):
        return []
    case (.bool, .bool):
        return []
    default:
        fatalError()
    }
}

func unify(_ s: [(Type, Type)]) -> Substitution {
    if let (x, y) = s.last {
        let t2 = unify(s.dropLast())
        let t1 = unifyOne(apply(t2, x), apply(t2, y))
        return t1 + t2
    } else {
        return []
    }
}


//
//  Infer.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation




struct Inferencer {
    typealias Ex = Expr<Int>
    
    var annotations: [Int: Type] = [:]
    private var count = 0
    
    
    
    
}

extension Inferencer {
    mutating func nextTypeVar() -> Type {
        defer { count += 1 }
        return .var(Type.Id(rawValue: "τ\(count)"))
    }
    
    // annotate all subexpressions with types
    // bv = stack of bound variables for which current expression is in scope
    // fv = hashtable of known free variables
    mutating func annotate(_ e: Ex) {
        let _tv = nextTypeVar()
        var table: [Variable: Type] = [
            "=": .arrow([_tv, _tv, .bool]),   // probably need a fresh type variable every time
            "+": .arrow([.int, .int, .int]),
            "-": .arrow([.int, .int, .int]),
            "*": .arrow([.int, .int, .int])
        ]
        
        @discardableResult
        func annotate_(_ e: Ex, _ bv: [(Variable, Type)]) -> Type {
            defer {
                assert(annotations[e.tag] != nil)
            }
            switch e {
            case let .var(x, tag):
                // bound variable?
                if let a = bv.first(where: { $0.0 == x })?.1 {
                    annotations[tag] = a
                    return a
                } else if let a = table[x] {
                    annotations[tag] = a
                    return a
                } else {
                    let a = nextTypeVar()
                    table[x] = a
                    annotations[tag] = a
                    return a
                }
            case let .abs(vars, body, tag):
                // assign a new type to each variable
                let newTypes = vars.map { ($0, nextTypeVar()) }
                var bv_ = bv
                bv_.append(contentsOf: newTypes)
                
                let bodyType = annotate_(body, bv_)
                let type = Type.arrow(newTypes.map { $0.1 } + [bodyType])
                annotations[tag] = type
                return type
                
            case let .cond(a, b, c, tag):
                annotate_(a, bv)
                let type = annotate_(b, bv)
                annotate_(c, bv)
                annotations[tag] = type
                return type
                
            case let .let(name, binding, body, tag):
                
                let bindingType = annotate_(binding, bv)
                
                var bv_ = bv
                bv_.append((name, bindingType))
                
                let type = annotate_(body, bv_)
                
//                let type = nextTypeVar()
                annotations[tag] = type
                return type
                
            case let .app(fn, args, tag):
                annotate_(fn, bv)
                args.forEach { annotate_($0, bv) }
                let type = nextTypeVar()
                annotations[tag] = type
                return type

            case let .lit(.int(_), tag):
                annotations[tag] = .int
                return .int
                
            case let .lit(.bool(_), tag):
                annotations[tag] = .bool
                return .bool
                
            case .lit(_, _):
                fatalError()
                
            case .set(_, _, _):
                fatalError()
                
            case let .seq(exprs, tag):
                exprs.forEach { annotate_($0, bv) }
                annotations[tag] = annotations[exprs.last!.tag]!
                return annotations[tag]!
            }
        }
        annotate_(e, [])
    }
    
    
    // collect constraints for unification
    func collect(_ expr: Expr<Int>) -> [(Type, Type)] {
        switch expr {
        case .var(_, _):
            return []
        case let .abs(_, ae, _):
            return collect(ae)
            
        case let .let(_, binding, body, tag):
            let type = annotations[tag]!
            let bindingType = annotations[binding.tag]!
            let bodyType = annotations[body.tag]!
            
            return collect(binding) + collect(body) + [(type, bodyType)]
            
        case let .cond(a, b, c, tag):
            let type = annotations[tag]!
            let aType = annotations[a.tag]!
            let bType = annotations[b.tag]!
            let cType = annotations[c.tag]!
            return collect(a) + collect(b) + collect(c) + [(aType, .bool), (bType, cType), (bType, type)]
            
        case let .app(fn, args, tag):
            let fnType = annotations[fn.tag]!
            let returnType = annotations[tag]!
            let argTypes = args.map { annotations[$0.tag]! }
            var result = collect(fn) + args.flatMap(collect(_:))
            result.append((fnType, .arrow(argTypes + [returnType])))
            return result
        case .lit(_, _):
            return []
            
        case let .seq(exprs, _):
            return exprs.flatMap { collect($0) }
        default:
            fatalError()
        }
    }
    
    // collect the constraints and perform unification
    mutating func infer(_ e: Expr<Int>) -> Type {
        annotate(e)
        let cl = collect(e)
        let s = unify(cl)
        let type = annotations[e.tag]!
        return apply(s, type)
    }
    
}

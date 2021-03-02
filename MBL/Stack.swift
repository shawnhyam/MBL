//
//  Stack.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

struct Stack {
    private var values: [Value] = []
    var tos: Int {
        get { values.count }
        set { values.removeLast(values.count - newValue) }
    }
    
    subscript(base: Int, offset:Int) -> Value {
        get {
            values[base-offset-1]
        }
        set {
            values[base-offset-1] = newValue
        }
    }
    
    mutating func push(_ x: Value) {
        values.append(x)
    }
    
    func findLink(base: Int, _ n: Int) -> Int {
        if n == 0 { return base }
        guard case let .stackAddr(link) = self[base, -1] else { fatalError() }
        return findLink(base: link, n-1)
    }
    
    mutating func shift(_ n: Int, _ m: Int) {
        (0..<n).reversed().forEach { i in
            self[tos, i+m] = self[tos, i]
        }
        tos -= m
    }
}

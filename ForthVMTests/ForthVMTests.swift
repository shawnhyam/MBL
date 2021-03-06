//
//  ForthVMTests.swift
//  ForthVMTests
//
//  Created by Shawn Hyam on 2021-03-05.
//

import XCTest
@testable import ForthVM

class ForthVMTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        //let program: [Inst] = [42, 24, .add, 3, .neg] + Inst.sub
        //let program: [Inst] = [42, .dup, .add]
        let program: [Inst] = [42, 13, .store, .drop, 13, .fetch]

        var machine = ForthVM()
        program.map { $0.machineCode }.enumerated().forEach { idx, code in machine.mem[idx] = code }
        for _ in 0..<6 {
            machine.step()
            print(machine.dStack, machine.mem[13])
        }
    }


}

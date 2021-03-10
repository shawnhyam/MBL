//
//  Tokenizer.swift
//  MBL
//
//  Created by Shawn Hyam on 2021-03-01.
//

import Foundation

enum Token: Equatable {
    case lparen
    case rparen
    case num(Int)
    case bool(Bool)
    case id(String)
    case str(String)
}

enum TokError: Error {
    case fail
    case endOfInput
}

extension CharacterSet {
    func containsUnicodeScalars(of character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}

public struct Tokenizer {
    private var input: Substring
    private var token: Result<Token, TokError>!
    
    public init(_ input: Substring) {
        self.input = input
        token = next()
    }
    
    let startIdChars = CharacterSet.letters.union(CharacterSet(charactersIn: "-'*="))
    let idChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-'*=!"))
    
    func peek() -> Result<Token, TokError> {
        return token!
    }
    
    @discardableResult
    mutating func eat(_ tok: Token? = nil) -> Result<Token, TokError> {
        let result = token
        if let tok = tok {
            assert(result == .success(tok))
        }
        token = next()
        return result!
    }
    
    private mutating func next() -> Result<Token, TokError> {
        guard let char = input.first else { return .failure(.endOfInput) }
        if char == "(" {
            input.removeFirst()
            return .success(.lparen)
        } else if char == ")" {
            input.removeFirst()
            return .success(.rparen)
        } else if char == "#" {
            input.removeFirst()
            if input.first == "t" {
                input.removeFirst()
                return .success(.bool(true))
            } else if input.first == "f" {
                input.removeFirst()
                return .success(.bool(false))
            }
                
        } else if startIdChars.containsUnicodeScalars(of: char) {
            let id = input.prefix(while: { idChars.containsUnicodeScalars(of: $0) })
            input.removeFirst(id.count)
            return .success(.id(String(id)))
        } else if CharacterSet.whitespacesAndNewlines.containsUnicodeScalars(of: char) {
            input.removeFirst()
            while let char = input.first, CharacterSet.whitespacesAndNewlines.containsUnicodeScalars(of: char) {
                input.removeFirst()
            }
            return next()
        } else if CharacterSet.decimalDigits.containsUnicodeScalars(of: char) {
            let id = input.prefix(while: { CharacterSet.decimalDigits.containsUnicodeScalars(of: $0) })
            input.removeFirst(id.count)
            return .success(.num(Int(id)!))

        }
        return .failure(.fail)
    }
}

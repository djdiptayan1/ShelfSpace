//
//  AnyEncodable.swift.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation

struct AnyEncodable: Encodable {
    let wrappedValue: Any
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        self.wrappedValue = wrapped
        self.encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

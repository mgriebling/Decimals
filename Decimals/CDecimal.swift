//
//  QDecimal.swift
//  Decimals
//
//  Created by Mike Griebling on 30 Jul 2017.
//  Copyright © 2017 Solinst Canada. All rights reserved.
//

import Foundation

extension Decimal : RealType {
    
    public func atan2(_ y: Decimal) -> Decimal { return self.arcTan2(b:y) }
    public func hypot(_ arg: Decimal) -> Decimal { return Decimal.zero }  // stub
    public func log() -> Decimal { return self.ln() }

    public var isSignaling: Bool { return self.isSpecial }
    public var isNormal: Bool    { return self.isNormal }
    public var isSignMinus: Bool { return self.isNegative }

    public init?(_ value: String) { self.init(value, digits: Decimal.digits, radix: 10) }
    public init(_ value: Float)   { self.init(value) }
    public init(_ value: Double)  { self.init(value) }
    public init(_ value: Int64)   { self.init(Int(value)) }
    public init(_ value: UInt64)  { self.init(UInt(value)) }
    public init(_ value: Int32)   { self.init(Int(value)) }
    public init(_ value: UInt32)  { self.init(UInt(value)) }
    public init(_ value: Int16)   { self.init(Int(value)) }
    public init(_ value: UInt16)  { self.init(UInt(value)) }
    public init(_ value: Int8)    { self.init(Int(value)) }
    public init(_ value: UInt8)   { self.init(UInt(value)) }
    
}

typealias CDecimal = Complex<Decimal>



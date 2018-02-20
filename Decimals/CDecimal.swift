//
//  QDecimal.swift
//  Decimals
//
//  Created by Mike Griebling on 30 Jul 2017.
//  Copyright © 2017 Solinst Canada. All rights reserved.
//

import Foundation

extension Decimal : RealType {

    public static func - (_ a: Decimal, _ b: Decimal) -> Decimal { return a.sub(b) }
    public static prefix func - (_ a: Decimal) -> Decimal { return a.negate() }
    
    public func atan2(_ y: Decimal) -> Decimal { return self.arcTan2(b:y) }
    public func hypot(_ arg: Decimal) -> Decimal { return self.hypot(y:arg) }

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

extension Decimal : Strideable {
    
    public func distance(to other: Decimal) -> Decimal.Stride { return self.sub(other) }
    public func advanced(by n: Decimal.Stride) -> Decimal { return self.add(n) }
    public typealias Stride = Decimal
    
}

extension Decimal : FloatingPoint {

    public static var nan: Decimal { return Decimal.NaN }
    public static var signalingNaN: Decimal { return Decimal.sNaN }
    
    public var ulp: Decimal { return self.eps }
    
    public static var leastNonzeroMagnitude: Decimal { return leastNormalMagnitude }
    
    public var sign: FloatingPointSign { if self.isNegative { return .minus } else { return .plus } }
    
    public mutating func formSquareRoot() { self = self.sqrt() }
    public mutating func addProduct(_ lhs: Decimal, _ rhs: Decimal) { self = self.mulAcc(lhs, c: rhs) }
    
    public func isEqual(to other: Decimal) -> Bool { return self.cmp(other) == .orderedSame }
    public func isLess(than other: Decimal) -> Bool { return self.cmp(other) == .orderedAscending }
    public func isLessThanOrEqualTo(_ other: Decimal) -> Bool {
        let result = self.cmp(other)
        return result == .orderedSame || result == .orderedAscending
    }
    
    public var isSignalingNaN: Bool { return self.floatingPointClass == .signalingNaN }
   
}

public typealias CDecimal = Complex<Decimal>



//
//  QDecimal.swift
//  Decimals
//
//  Created by Mike Griebling on 30 Jul 2017.
//  Copyright © 2017 Solinst Canada. All rights reserved.
//

import Foundation

extension Decimal : RealType {
   
//    public static var nan: Decimal { return Decimal.NaN }
//    public static var signalingNaN: Decimal { return  Decimal(0) }
//    public static var greatestFiniteMagnitude: Decimal {  return  Decimal(0) }
//    public var ulp: Decimal {  return  Decimal(0) }
//    public static var leastNormalMagnitude: Decimal {  return  Decimal(0) }
//    public static var leastNonzeroMagnitude: Decimal {  return  Decimal(0) }
//
//    public var sign: FloatingPointSign { if self.isNegative { return .minus } else { return .plus } }
//    public var significand: Decimal {  return  Decimal(0) }
//
//    public mutating func formRemainder(dividingBy other: Decimal) -> Decimal {  return  Decimal(0) }
//    public mutating func formTruncatingRemainder(dividingBy other: Decimal) -> Decimal {  return  Decimal(0) }
//    public mutating func formSquareRoot() -> Decimal {  return  Decimal(0) }
//    public mutating func addProduct(_ lhs: Decimal, _ rhs: Decimal) -> Decimal {  return  Decimal(0) }
//    public mutating func round(_ rule: FloatingPointRoundingRule) -> Decimal {  return  Decimal(0) }
//
//    public var nextUp: Decimal {  return  Decimal(0) }
//
//    public func isEqual(to other: Decimal) -> Bool { return true }
//    public func isLess(than other: Decimal) -> Bool {  return true }
//    public func isLessThanOrEqualTo(_ other: Decimal) -> Bool {  return true }
//    public func isTotallyOrdered(belowOrEqualTo other: Decimal) -> Bool {  return true }
//
//    public var isCanonical: Bool {  return true }
//    public var isSignalingNaN: Bool { return true }

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

typealias CDecimal = Complex<Decimal>



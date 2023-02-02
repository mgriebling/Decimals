//
//  Utilities.swift
//  DecNumber
//
//  Created by Mike Griebling on 2021-12-17.
//  Copyright © 2021 Computer Inspirations. All rights reserved.
//

import Foundation
import CDecNumber
import Numerics

// protocol to allow HDecimal, Decimal32, Decimal64, Decimal128 to use some common operations
public protocol DecReals: Real {

    static var maximumDigits: Int { get }
    
    var bcd: [UInt8] { get }
    var bytes: [UInt8] { get }
    
    init(sign: FloatingPointSign, bcd: [UInt8], exponent: Int)
    init(_ value: HDecimal)
    init?(_ s: String, radix: Int)
    
}

extension DecReals {
    
    public var int: Int { Utilities.realToInt(self) }
    public var uint: UInt { Utilities.realToInt(self) }
    public var doubleValue: Double { Utilities.doubleValue(of: self) }
    
    public var debugDescription: String {
        var str = ""
        bytes.forEach { str += String(format: "%02X", $0) }
        return str
    }
    
}

extension HDecimal : DecReals { }
extension Decimal32 : DecReals  { }
extension Decimal64 : DecReals  { }
extension Decimal128 : DecReals  { }

/// A collection of generic algorithms used in the Decimal functions
struct Utilities {
    
    static let piString = "3.141592653589793238462643383279502884197169399375105820974944592307816406286" +
    "208998628034825342117067982148086513282306647093844609550582231725359408128481" +
    "117450284102701938521105559644622948954930381964428810975665933446128475648233" +
    "786783165271201909145648566923460348610454326648213393607260249141273724587006"
    
    static let ln2String = "0.6931471805599453094172321214581765680755001343602552541206800094933936219696" +
    "94715605863326996418687542001481020570685733685520235758130557032670751635075" +
    "96193072757082837143519030703862389167347112335011536449795523912047517268157" +
    "493206515552473413952588295045300709532636664265410423915781495204374"
    
    /// Returns a real number for the integer _n_ where the real and
    /// integer can be any types conforming to the _Real_ and
    /// _BinaryInteger_ protocols.
    public static func intToReal<T:BinaryInteger,S:Real>(_ int: T) -> S {
        var x = S.zero
        var n = int.magnitude
        var m = S(1)
        let d = 1_000_000_000 // base
        let rd = S(d)
        let id = T(d)
        while n != 0 {
            let qr = n.quotientAndRemainder(dividingBy: T.Magnitude(id))
            n = qr.quotient
            if qr.remainder != 0 { x.addProduct(m, S(qr.remainder)) }
            m *= rd
        }
        return int.signum() < 0 ? -x : x
    }
    
    public static func realToInt<R:DecReals, I:FixedWidthInteger>(_ n: R) -> I {
        if n.magnitude < 1 { return 0 }  // check for fractions, magnitude >= 0
        if n >= R(I.max) { return I.max }
        if n <= R(I.min) { return I.min }
        
        /// value must be in range of the return integer type
        let digits = truncateLeadingZeros(round(n.magnitude).bcd) // round any fractions & get bcd digits
        var x = I.zero
        for digit in digits {
            x *= 10
            x += I(digit)
        }
        return n.isNegative ? (0-x) : x
    }
    
    private static func truncateLeadingZeros(_ n: [UInt8]) -> [UInt8] { Array(n.drop{ $0 == 0 }) }
    
    public static func doubleToReal<S:DecReals>(_ n: Double) -> S {
        // extract the numbers digits
        if n.isZero { return S.zero }  // special case due to large exponent
        
        let mantBits  = 52 // + 1 hidden
        let hiddenBit : UInt64 = 1 << mantBits
        let bitMask   = hiddenBit-1
        let bits = (n.bitPattern & bitMask) + hiddenBit
        let exponent = Int(n.exponent)-mantBits
        
        // need a bit more resolution to get optimal accuracy -- HDecimal is all we have
        let nbits = HDecimal(bits)
        let npower = Utilities.power(HDecimal(2), to: abs(exponent))
        let result = exponent < 0 ? nbits / npower : nbits * npower
        return S(result)
    }
    
    public static func convert<T:Real> (num: T, fromBase from: Int, toBase base: Int) -> T {
        let to = T(base)
        let from = T(from)
        var y = T.zero
        var n = num
        var scale = T(1)
        while n != 0 {
            let digit = n.truncatingRemainder(dividingBy: to)
            y += scale * digit
            n = trunc(n / to)
            scale *= from
        }
        return y
    }
    
    // Mark: - Standard Functions

    /// Returns sqrt(x² + y²)
    public static func hypot<T:Real>(x:T, y:T) -> T{
        var x = abs(x)
        let y = abs(y)
        var t = min(x, y)
        x = max(x, y)
        t /= x
        return sqrt(x*(1+t*t))
    }
    
    /// Returns x^exp where x = *num*.
    /// - Precondition: x ≥ 0
    public static func power<T:Real>(_ num:T, to exp: Int) -> T {
        // Zero raised to anything except zero is zero (provided exponent is valid)
        if num.isZero { return exp == 0 ? 1 : 0 }
        var z = num
        var y : T = 1
        var n = abs(exp)
        while true {
            if !n.isMultiple(of: 2) { y *= z }
            n >>= 1
            if n == 0 { break }
            z *= z
        }
        return exp < 0 ? 1 / y : y
    }
    
//    fileprivate static func digitToInt(_ digit: Character, radix: Int) -> Int? {
//        let radixDigits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
//        if let digitIndex = radixDigits.firstIndex(of: digit) {
//            return radixDigits.distance(from: radixDigits.startIndex, to:digitIndex)
//        }
//        return nil   // Error illegal radix character
//    }
    
    ///
    /// Returns the approximate value of decimal number _num_ as a double
    ///
    public static func doubleValue<T:DecReals>(of num: T) -> Double {
        // Return NaN if number is not valid
        if !num.isValid { return Double.nan }
        
        // Extract all the digits out and put them in the double
        var retVal = 0.0
        let digits = num.bcd
        let exp = num.exponent
        let radix = Double(T.radix)
        for digit in digits {
            retVal = fma(retVal, radix, Double(digit))
        }
        
        // Apply the sign
        if num.isNegative { retVal *= -1 }
        
        // Apply the exponent
        retVal *= Utilities.power(radix, to: Int(exp))
        return retVal
    }
    
    /// Returns x! = x(x-1)(x-2)...(2)(1) where *x* = *self*.
    /// - Precondition: *x* ≥ 0
    public static func factorial<T:DecReals>(_ n: T) -> T {
        let x = trunc(n)
        if x.isNegative { return T.zero}    /* out of range */
        if x < T(2) { return T(1) }     /* 0! & 1! */
        
        var f = T(1)
        for i in stride(from: T(2), through: x, by: 1) {
            f *= i
        }
        return f
    }
    
    public static func root<T:Real>(value: T, n: Int) -> T {
        if !value.isValid { return value }
        
        // oddly-numbered roots of negative numbers should work
        if value.isNegative && n.isMultiple(of: 2) { return T.nan }
        
        let original = abs(value)
        let root = T(n)
        
        // The first guess will be the scaled number
        var prevGuess = original + 1
        var newGuess = original / root
        
        // Do some Newton's method iterations until we converge
        var maxIterations = 1000
        var power = T.zero
        while newGuess != prevGuess && maxIterations > 0 {
            prevGuess = newGuess
            newGuess = original
            power = Utilities.power(prevGuess, to: n-1)
            newGuess /= power
            newGuess -= prevGuess
            newGuess /= root
            newGuess += prevGuess
            maxIterations -= 1
        }
        if maxIterations <= 0 { NSLog("Exceeded iteration limit on root evaluation: Error is likely") }
        
        // fix the sign
        return value.isNegative ? -newGuess : newGuess
    }
    
    /// Performs 1/self.
    public static func inverse<T:Real>(_ value: T) -> T {
        if !value.isValid { return value }
        if value.isZero { return T.infinity }
        return 1/value
    }
    
    /// Returns the value e^x where x is the input _value_.
    public static func exp<T:Real>(_ value: T) -> T {
        var result = abs(value)
        if !value.isValid { return value }
        
        // Pre-scale the number to aid convergeance
        var squares = 0
        while result > 1 {
            result /= 2
            squares += 1
        }
        
        // Initialise stuff
        let one = T(1)
        var factorialValue = one
        var prevIteration = one
        let original = result
        var powerCopy = result
        
        // Set the current value to 1 (the zeroth term)
        result = one
        
        // Add the second term
        result += original
        
        // otherwise iterate the Taylor Series until we obtain a stable solution
        var i = 2
        var nextTerm = factorialValue
        while result != prevIteration {
            // Get a copy of the current value so that we can see if it changes
            prevIteration = result
            
            // Determine the next term of the series
            powerCopy *= original
            
            factorialValue *= T(i)
            nextTerm = powerCopy / factorialValue
            
            // Add the next term if it is valid
            if nextTerm.isValid {
                result += nextTerm
            }
            
            i += 1
        }
        
        // Reverse the prescaling
        while squares > 0 {
            result *= result
            squares -= 1
        }
        
        return value.isNegative ? Utilities.inverse(result) : result
    }
    
    //
    // Raises the _value_ to the exponent _num_.
    //
    public static func pow<T:DecReals>(_ value: T, _ num: T) -> T {
        var numCopy = num
        var result = value
        
        if !value.isValid { return value }
        if !num.isValid { return num }
        
        if value.isZero {
            // Zero raised to anything except zero is zero (provided exponent is valid)
            if num.isZero { return T(1) }
            return value
        }
        
        let exp:Int = Utilities.realToInt(num)
        if T(exp)-num == 0 {
            return power(value, to: exp)
        }
        
        if value.isNegative {
            result = value.magnitude
        }
        
        result = T.exp(T.log(result) * num)
        if value.isNegative {
            if numCopy.isNegative {
                numCopy = -numCopy
            }
            numCopy = numCopy.remainder(dividingBy: T(2))  // %= T(2)
            if numCopy == T(1) {
                result = -result
            } else if !numCopy.isZero {
                result = T.nan
            }
            
        }
        return result
    }

}

extension Real {
    
    fileprivate var isNegative: Bool { self.sign == .minus }
    fileprivate var isValid: Bool { self.isNormal || self.isSubnormal }
    
    // Mark: - Convenience functions
    public func sqr() -> Self { self * self }
    public var ² : Self { sqr() }
    
    // Mark: - Operators
    static public func /= (a: inout Self, b: Self) { a = a / b }
    static public func **= (a: inout Self, b: Self) { a = a ** b }
    
    static public func ** (base: Self, power: Int) -> Self { Utilities.power(base, to: power) }
    static public func ** (base: Int, power: Self) -> Self { Self(base) ** power }
    static public func ** (base: Self, power: Self) -> Self { pow(base, power)   } 
    
}

public protocol DecNumbers { }  // protocol to allow decNumbers, decSingles, decQuads, decDoubles to use some common operations

extension decNumber : DecNumbers { }
extension decSingle : DecNumbers { }
extension decDouble : DecNumbers { }
extension decQuad   : DecNumbers { }

public protocol LogicalOperations : Real {
    
    associatedtype T : DecNumbers
    associatedtype R : DecNumbers
    
    init(_ s: T)
    init(_ s: R)
    
    func decOr(_ a:UnsafeMutablePointer<T>!, _ b:UnsafePointer<T>!, _ c:UnsafePointer<T>!)
    func decAnd(_ a:UnsafeMutablePointer<T>!, _ b:UnsafePointer<T>!, _ c:UnsafePointer<T>!)
    func decXor(_ a:UnsafeMutablePointer<T>!, _ b:UnsafePointer<T>!, _ c:UnsafePointer<T>!)
    func decShift(_ a:UnsafeMutablePointer<T>!, _ b:UnsafePointer<T>!, _ c:UnsafePointer<T>!)
    func decRotate(_ a:UnsafeMutablePointer<T>!, _ b:UnsafePointer<T>!, _ c:UnsafePointer<T>!)
    func decInvert(_ a:UnsafeMutablePointer<T>!, _ b:UnsafePointer<T>!)
    func decFromString(_ a: UnsafeMutablePointer<R>!, s: String)
    
    func logical() -> T
    func copy() -> T
    func base10(_ a: T) -> Self
    func negate() -> Self
    func div (_ b: Self) -> Self
    func remainder (_ b: Self) -> Self
    
    var single: R { get }
    
    var zero: T { get }
    var abs: Self { get }
}

public extension LogicalOperations {
    
    // Mark: - Operators
    static func % (lhs: Self, rhs: Self) -> Self { lhs.remainder(rhs) }
    static func %= (a: inout Self, b: Self) { a = a % b }
    static func / (lhs: Self, rhs: Self) -> Self { lhs.div(rhs) }
    
    // MARK: - Logical Operations
    func or (_ a: Self) -> Self {
        var b = a.logical()
        var a = self.logical()
        var result = zero
        decOr(&result, &a, &b)
        return base10(result)
    }

    func and (_ a: Self) -> Self {
        var b = a.logical()
        var a = self.logical()
        var result = zero
        decAnd(&result, &a, &b)
        return base10(result)
    }

    func xor (_ a: Self) -> Self {
        var b = a.logical()
        var a = self.logical()
        var result = zero
        decXor(&result, &a, &b)
        return base10(result)
    }

    func not () -> Self {
        var a = self.logical()
        var result = zero
        decInvert(&result, &a)
        return base10(result)
    }

    func shift (_ a: Self) -> Self {
        var a = a.copy()
        var b = self.logical()
        var result = zero
        decShift(&result, &b, &a)
        return base10(result)
    }

    func rotate (_ a: Self) -> Self {
        var a = a.copy()
        var b = self.logical()
        var result = zero
        decRotate(&result, &b, &a)
        return base10(result)
    }
    
    /// Converts a decimal number string to a Decimal number
    func numberFromString(_ string: String, digits: Int = 0, radix: Int = 10) -> Self? {
        var string = string.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "_", with: "")
        var radix = radix
        if string.hasPrefix("0x") { string.removeFirst(2); radix = 16 }
        if string.hasPrefix("0o") { string.removeFirst(2); radix = 8 }
        if string.hasPrefix("0b") { string.removeFirst(2); radix = 2 }
        if string.hasSuffix("₁₆") { string.removeLast(2); radix = 16 }
        if string.hasSuffix("₈")  { string.removeLast(); radix = 8 }
        if string.hasSuffix("₂")  { string.removeLast(); radix = 2 }
        if radix == 10 {
            // use library function for string conversion
            var number = single
            decFromString(&number, s: string)
            return Self(number)
        } else {
            // convert non-base 10 string to an integral Decimal number
            let ls = string.uppercased()  // force uppercase
            var number = Self(0)
            let radixNumber = Self(radix)
            for digit in ls {
                if let digitNumber = Int(String(digit), radix: radix) {
                    number = fma(number, radixNumber, Self(digitNumber))
                } else {
                    return nil
                }
            }
            return number
        }
    }
    
    //
    // Logical operators
    //
    
    static func & (a: Self, b: Self) -> Self { a.and(b) }
    static func | (a: Self, b: Self) -> Self { a.or(b) }
    static func ^ (a: Self, b: Self) -> Self { a.xor(b) }
    static prefix func ~ (a: Self) -> Self { a.not() }

    static func &= (a: inout Self, b: Self) { a = a & b }
    static func |= (a: inout Self, b: Self) { a = a | b }
    static func ^= (a: inout Self, b: Self) { a = a ^ b }
    
    static func << (a: Self, b: Self) -> Self { a.shift(b.abs) }
    static func >> (a: Self, b: Self) -> Self { a.shift(b.abs.negate()) }
    
}

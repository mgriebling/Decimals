//
//  Decimal.swift
//  TestDecimals
//
//  Created by Mike Griebling on 4 Sep 2015.
//  Copyright © 2015 Computer Inspirations. All rights reserved.
//
//  Notes: The maximum decimal number size is currently hard-limited to 120 digits
//  via DECNUMDIGITS.  The number of digits per exponent is fixed at six to allow
//  mathematical functions to work.
//

import Foundation

public struct Decimal {
    
    public enum Round : UInt32 {
        // A bit kludgey -- I couldn't directly map the decNumber "rounding"
        // enum to Swift.
        case ceiling,       /* round towards +infinity         */
        up,                 /* round away from 0               */
        halfUp,             /* 0.5 rounds up                   */
        halfEven,           /* 0.5 rounds to nearest even      */
        halfDown,           /* 0.5 rounds down                 */
        down,               /* round towards 0 (truncate)      */
        floor,              /* round towards -infinity         */
        r05Up,              /* round for reround               */
        max                 /* enum must be less than this     */
        
        init(_ r: rounding) {
            self = Round(rawValue: r.rawValue)!
        }
        
        var crounding : rounding {
            return rounding(self.rawValue)
        }
    }
    
    static let maximumDigits = Int(DECNUMDIGITS)
    static let nominalDigits = 34  // roughly number of decimal digits in 128 bits
    static var context = decContext()
    fileprivate var decimal = decNumber()
    private static let errorFlags = UInt32(DEC_IEEE_754_Division_by_zero | DEC_IEEE_754_Overflow |
        DEC_IEEE_754_Underflow | DEC_Conversion_syntax | DEC_Division_impossible |
        DEC_Division_undefined | DEC_Insufficient_storage | DEC_Invalid_context | DEC_Invalid_operation)
    
    private func initContext(digits: Int) {
        if Decimal.context.digits == 0 && digits <= Decimal.maximumDigits {
            decContextDefault(&Decimal.context, DEC_INIT_BASE)
            Decimal.context.traps = 0
            Decimal.context.digits = Int32(digits)
//            Decimal.context.round = Round.HalfEven.crounding  // used in banking
//            Decimal.context.round = Round.HalfUp.crounding    // default if not specified
        }
    }
    
    // MARK: - Status Methods
    
    public static var errorString : String {
        let flags = context.status & errorFlags
        if flags == 0 { return "" }
        context.status &= errorFlags
        let errorString = decContextStatusToString(&context)
        return String(cString: errorString!)
    }
    
    public static func clearStatus() { decContextZeroStatus(&context) }
    
    public static var roundMethod : Round {
        get { return Round(decContextGetRounding(&Decimal.context)) }
        set { decContextSetRounding(&Decimal.context, newValue.crounding) }
    }
    
    public static var digits : Int {
        get { return Int(context.digits) }
        set { if newValue > 0 && newValue <= maximumDigits { context.digits = Int32(newValue) } }
    }
    
    // MARK: - Initialization Methods
    
    public init() { self.init(0) }    // default value is 0
    
    public init(_ uint: UInt) {
        initContext(digits: Decimal.nominalDigits)
        decNumberFromUInt32(&decimal, UInt32(uint))
    }
    
    public init(_ int: Int) {
        initContext(digits: Decimal.nominalDigits)
        decNumberFromInt32(&decimal, Int32(int))
    }
    
    public init(_ s: String, digits: Int = Decimal.nominalDigits) {
        initContext(digits: digits)
        decNumberFromString(&decimal, s, &Decimal.context)
    }
    
    public init(_ s: [UInt8], exponent: Int = 0) {
        var s = s
        initContext(digits: s.count)
        decNumberSetBCD(&decimal, &s, UInt32(s.count))
        var exp = decNumber()
        decNumberFromInt32(&exp, Int32(exponent))
        decNumberScaleB(&decimal, &decimal, &exp, &Decimal.context)
    }
    
    fileprivate init(_ d: decNumber) {
        initContext(digits: Int(d.digits))
        decimal = d
    }
    
    // MARK: - Archival Operations
    
    static var UInt8Type = "C".cString(using: String.Encoding.ascii)!
    static var Int32Type = "l".cString(using: String.Encoding.ascii)!
    
    public init (coder: NSCoder) {
        var scale : Int32 = 0
        var size : Int32 = 0
        coder.decodeValue(ofObjCType: &Decimal.Int32Type, at: &size)
        coder.decodeValue(ofObjCType: &Decimal.Int32Type, at: &scale)
        var bytes = [UInt8](repeating: 0, count: Int(size))
        coder.decodeArray(ofObjCType: &Decimal.UInt8Type, count: Int(size), at: &bytes)
        decPackedToNumber(&bytes, Int32(size), &scale, &decimal)
    }
    
    public func encodeWithCoder(_ coder: NSCoder) {
        var local = decimal
        var scale : Int32 = 0
        var size = decimal.digits/2+1
        var bytes = [UInt8](repeating: 0, count: Int(size))
        decPackedFromNumber(&bytes, size, &scale, &local)
        coder.encodeValue(ofObjCType: &Decimal.Int32Type, at: &size)
        coder.encodeValue(ofObjCType: &Decimal.Int32Type, at: &scale)
        coder.encodeArray(ofObjCType: &Decimal.UInt8Type, count: Int(size), at: &bytes)
    }
    
    // MARK: - Accessor Operations 
    
    public var engineeringString : String {
        var cs = [CChar](repeating: 0, count: Int(decimal.digits+14))
        var local = self.decimal
        decNumberToEngString(&local, &cs)
        return String(cString: &cs)
    }
    
    public static var decNumberVersionString : String {
        return String(cString: decNumberVersion())
    }
    
    public var int : Int {
        var local = self.decimal
        return Int(decNumberToInt32(&local, &Decimal.context))
    }
    
    public var uint : UInt {
        var local = self.decimal
        return UInt(decNumberToUInt32(&local, &Decimal.context))
    }
    
    /// Returns the type of number (e.g., "NaN", "+Normal", etc.)
    public var numberClass : String {
        var a = self.decimal
        let cs = decNumberClassToString(decNumberClass(&a, &Decimal.context))
        return String(cString: cs!)
    }
    
    /// Returns all digits of the binary-coded decimal (BCD) digits of the number with
    /// one value (0 to 9) per byte.
    public var bcd : [UInt8] {
        var result = [UInt8](repeating: 0, count: Int(decimal.digits))
        var a = decimal
        decNumberGetBCD(&a, &result)
        return result
    }
    
    public var scale : Int { return Int(decimal.exponent) }
    public var eps : Decimal {
        var local = decimal
        var result = decNumber()
        decNumberNextPlus(&result, &local, &Decimal.context)
        decNumberSubtract(&result, &result, &local, &Decimal.context)
        return Decimal(result)
    }
    
    private let DECSPECIAL = UInt8(DECINF|DECNAN|DECSNAN)
    public var isFinite : Bool   { return decimal.bits & DECSPECIAL == 0 }
    public var isInfinite: Bool  { return decimal.bits & UInt8(DECINF) != 0 }
    public var isNaN: Bool       { return decimal.bits & UInt8(DECNAN|DECSNAN) != 0 }
    public var isNegative: Bool  { return decimal.bits & UInt8(DECNEG) != 0 }
    public var isZero: Bool      { return isFinite && decimal.digits == 1 && decimal.lsu.0 == 0 }
    public var isSubnormal: Bool { var n = decimal; return decNumberIsSubnormal(&n, &Decimal.context) == 1 }
    public var isInteger: Bool {
        var local = decimal
        decNumberToIntegralExact(&local, &local, &Decimal.context)
        if Decimal.context.status & UInt32(DEC_Inexact) != 0 {
            decContextClearStatus(&Decimal.context, UInt32(DEC_Inexact)); return false
        }
        return true
    }
    
    /// Returns true if the number can be used in logical operations (i.e., is an integer and only contains
    /// digits 0 and 1).
    public var isLogical: Bool {
        if !isInteger { return false }
        let digits = bcd.filter(){ $0 > 1 }
        return digits.count == 0
    }

    // MARK: - Basic Operations
    
    /// Removes all trailing zeros without changing the value of the number.
    public func normalize () -> Decimal {
        var a = self.decimal
        decNumberNormalize(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public func integer () -> Decimal {
        var a = self.decimal
        decNumberToIntegralValue(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func remainder (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberRemainder(&a, &a,  &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func negate () -> Decimal {
        var a = self.decimal
        decNumberMinus(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func max (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberMax(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func min (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberMin(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func abs () -> Decimal {
        var a = self.decimal
        decNumberAbs(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func add (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberAdd(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func sub (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberSubtract(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func mul (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberMultiply(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func div (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberDivide(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func idiv (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberDivideInteger(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }

    /// Rounds to *digits* places where negative values limit the decimal places
    /// and positive values limit the number to multiples of 10 ** digits.
    public func round (_ digits: Int) -> Decimal {
        var a = self.decimal
        var b = Decimal(digits)
        decNumberRescale(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    // MARK: - Scientific Operations
    
    public func pow (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberPower(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func exp () -> Decimal {
        var a = self.decimal
        decNumberExp(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Natural logarithm
    public func log () -> Decimal {
        var a = self.decimal
        decNumberLn(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func log10 () -> Decimal {
        var a = self.decimal
        decNumberLog10(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Base 10 or binary logarithm
    public func logB () -> Decimal {
        var a = self.decimal
        decNumberLogB(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Returns self * 10 ** b
    public func scaleB (_ b: Decimal) -> Decimal {
        var a = self.decimal
        decNumberLogB(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func sqrt () -> Decimal {
        var a = self.decimal
        decNumberSquareRoot(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    
    // MARK: - Logical Operations
    
    public func or (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberOr(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func and (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberAnd(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func xor (_ b: Decimal) -> Decimal {
        var b = b
        var a = self.decimal
        decNumberXor(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func not () -> Decimal {
        var a = self.decimal
        decNumberInvert(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func shift (_ bits: Decimal) -> Decimal {
        var bits = bits
        var a = self.decimal
        decNumberShift(&a, &a, &bits.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func rotate (_ bits: Decimal) -> Decimal {
        var bits = bits
        var a = self.decimal
        decNumberRotate(&a, &a, &bits.decimal, &Decimal.context)
        return Decimal(a)
    }
}

extension Decimal : CustomStringConvertible {
    
    public var description : String  {
        var cs = [CChar](repeating: 0, count: Int(decimal.digits+14))
        var local = self.decimal
        decNumberToString(&local, &cs)
        return String(cString: &cs)
    }
    
}

extension Decimal : Comparable {
    
    public func cmp (_ b: Decimal) -> ComparisonResult {
        var b = b
        var a = self.decimal
        decNumberCompare(&a, &a, &b.decimal, &Decimal.context)
        let ai = decNumberToInt32(&a, &Decimal.context)
        switch ai {
        case -1: return .orderedAscending
        case 0:  return .orderedSame
        default: return .orderedDescending
        }
    }
    
}

public func == (lhs: Decimal, rhs: Decimal) -> Bool {
    return lhs.cmp(rhs) == .orderedSame
}

public func < (lhs: Decimal, rhs: Decimal) -> Bool {
    return lhs.cmp(rhs) == .orderedAscending
}

extension Decimal : ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) { self.init(value) }
    
}

extension Decimal : ExpressibleByStringLiteral {
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    public init (stringLiteral s: String) { self.init(s) }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
    
}

extension Decimal : RealOperations {
    
    public func sqr() -> Decimal { return self * self }
    
}

//
// Mathematical operators
//

public func % (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.remainder(rhs) }
public func * (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.mul(rhs) }
public func + (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.add(rhs) }
public func - (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.sub(rhs) }
public func / (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.div(rhs) }

public prefix func - (a: Decimal) -> Decimal { return a.negate() }
public postfix func -- (a: inout Decimal) { a = a - 1 }
public func -= (a: inout Decimal, b: Decimal) { a = a - b }

public prefix func + (a: Decimal) -> Decimal { return a }
public postfix func ++ (a: inout Decimal) { a = a + 1 }
public func += (a: inout Decimal, b: Decimal) { a = a + b }

public func *= (a: inout Decimal, b: Decimal) { a = a * b }
public func /= (a: inout Decimal, b: Decimal) { a = a / b }

infix operator ** : ExponentPrecedence // { associativity left precedence 170 }
precedencegroup ExponentPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}
public func ** (base: Decimal, power: Int) -> Decimal { return base ** Decimal(power) }
public func ** (base: Int, power: Int) -> Decimal { return Decimal(base) ** power }
public func ** (base: Decimal, power: Decimal) -> Decimal { return base.pow(power) }

//
// Logical operators
//

public func & (a: Decimal, b: Decimal) -> Decimal { return a.and(b) }
public func | (a: Decimal, b: Decimal) -> Decimal { return a.or(b) }
public func ^ (a: Decimal, b: Decimal) -> Decimal { return a.xor(b) }
public prefix func ~ (a: Decimal) -> Decimal { return a.not() }

public func << (a: Decimal, b: Decimal) -> Decimal { return a.shift(b.abs()) }
public func >> (a: Decimal, b: Decimal) -> Decimal { return a.shift(-b.abs()) }


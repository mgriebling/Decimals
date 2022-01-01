
import Foundation
import CDecNumber
import Numerics

///
///  The **Decimal128** struct provides a Swift-based interface to the decNumber C library
///  by Mike Cowlishaw. There are no guarantees of functionality for a given purpose.
///  If you do fix bugs or missing functions, I'd appreciate getting updates of the source.
///
///  The main reason for this library was to provide a decimal-number based datatype
///  that is space-efficient (128 bits) and comparable to Apple's **Decimal** type.
///  I've also added compliance to the new ``swift_numerics`` _Real_ protocol and provided
///  an instance of the **Complex** generic for **Decimal128**.
///
///  Notes: The maximum **Decimal128** number size is 34 digits with an exponent range
///  from 10⁻⁶¹⁴³ to 10⁺⁶¹⁴⁴. The endianess is currently hard-coded via
///  ``DECLITEND`` as little-endian.
///
///  Created by Mike Griebling on 17 Dec 2021
///  Copyright © 2021 Computer Inspirations. All rights reserved.
///
public struct Decimal128 {
    
    /// Class properties
    public static let maximumDigits = Int(DECIMAL128_Pmax)
    
    static var context = DecContext(initKind: .dec128)
    
    /// Active angular measurement unit
    public static var angularMeasure = UnitAngle.radians
    
    /// Internal number representation
    fileprivate var decimal = decimal128()
    
    // MARK: - Internal Constants
    public static let pi = Decimal128(Utilities.piString)!
    public static let radix = 10
    public static let π = pi
    public static let zero = Decimal128(0)
    public static let one = Decimal128(1)
    public static let two = Decimal128(2)
    
    // MARK: - Initialization Methods
    
    public init(_ decimal: Decimal128) { self.decimal = decimal.decimal }
    private init(_ number: decimal128) { decimal = number }
    public init(_ value: decQuad)  { decimal.bytes = value.bytes }
    
    public init<Source>(_ value: Source = 0) where Source : BinaryInteger {
        /* small integers (32-bits) are directly convertible */
        if let rint = Int32(exactly: value) {
            // need this to initialize small Ints
            var double = decQuad()
            decQuadFromInt32(&double, rint)
            self.init(double)
        } else {
            let x: Decimal128 = Utilities.intToReal(value)
            self.init(x)
        }
    }
    
    public init?(_ s: String, radix: Int = 10) {
        if let x = numberFromString(s, digits: 0, radix: radix) {
            decimal = x.decimal; return
        }
        return nil
    }
    
    public init(_ d: Double) {
        // we cheat by first converting to a string since Double conversions aren't accurate anyway
        let n: Decimal128 = Utilities.doubleToReal(d)
        self.decimal = n.decimal
    }
    
    public init(sign: FloatingPointSign, bcd: [UInt8], exponent: Int) {
        var bcd = bcd
        while bcd.count < Decimal128.maximumDigits { bcd.insert(0, at: 0) }
        var x = decQuad()
        decQuadSetCoefficient(&x, &bcd, sign == .minus ? 1 : 0)
        decQuadSetExponent(&x, &Decimal128.context.base, Int32(exponent))
        self.init(x)
    }
    
    // MARK: - Accessor Operations
    
    public var engineeringString : String {
        var cs = [CChar](repeating: 0, count: Int(DECIMAL128_String))
        var local = decimal
        decimal128ToEngString(&local, &cs)
        return String(cString: &cs)
    }
    
    public static var versionString : String { String(cString: decQuadVersion()) }
    
    /// Returns the type of number (e.g., "NaN", "+Normal", etc.)
    public var numberClass : String {
        var a = self.quad
        let cs = decNumberClassToString(decQuadClass(&a))
        return String(cString: cs!)
    }
    
    public var floatingPointClass: FloatingPointClassification {
        var a = self.quad
        let c = decQuadClass(&a)
        switch c {
        case DEC_CLASS_SNAN: return .signalingNaN
        case DEC_CLASS_QNAN: return .quietNaN
        case DEC_CLASS_NEG_INF: return .negativeInfinity
        case DEC_CLASS_POS_INF: return .positiveInfinity
        case DEC_CLASS_NEG_ZERO: return .negativeZero
        case DEC_CLASS_POS_ZERO: return .positiveZero
        case DEC_CLASS_NEG_NORMAL: return .negativeNormal
        case DEC_CLASS_POS_NORMAL: return .positiveNormal
        case DEC_CLASS_POS_SUBNORMAL: return .positiveSubnormal
        case DEC_CLASS_NEG_SUBNORMAL: return .negativeSubnormal
        default: return .positiveZero
        }
    }
    
    public static var roundMethod : rounding {
        get { decContextGetRounding(&context.base) }
        set { decContextSetRounding(&context.base, newValue) }
    }
    
    /// Returns all digits of the binary-coded decimal (BCD) digits of the number with
    /// one value (0 to 9) per byte.  The first array byte is the exponent.
    public var bcd : [UInt8] {
        var result = [UInt8](repeating: 0, count: Decimal128.maximumDigits)
        var a = self.quad
        var exp : Int32 = 0
        decQuadToBCD(&a, &exp, &result)
        return result
    }
    
    private var quad: decQuad { decQuad(bytes: decimal.bytes) }
    
    public var exponent : Int {
        var dec = self.quad
        return Int(decQuadGetExponent(&dec))
    }
    
    public var eps : Decimal128 {
        var local = self.quad
        var result = decQuad()
        decQuadNextPlus(&local, &result, &Decimal128.context.base)
        var result2 = decQuad()
        decQuadSubtract(&result2, &result, &local, &Decimal128.context.base)
        return Decimal128(result2)
    }
    
    public var isFinite : Bool {
        var n = self.quad
        return decQuadIsFinite(&n) == 1
    }
    
    public var isInfinite: Bool {
        var n = self.quad
        return decQuadIsInfinite(&n) == 1
    }
    
    public var isNaN: Bool {
        var n = self.quad
        return decQuadIsNaN(&n) == 1
    }
    
    public var isNegative: Bool {
        var n = self.quad
        return decQuadIsNegative(&n) == 1
    }
    
    public var isZero: Bool {
        var n = self.quad
        return decQuadIsZero(&n) == 1
    }
    
    public var isSubnormal: Bool {
        var n = self.quad
        return decQuadIsSubnormal(&n) == 1
    }

    public var isCanonical: Bool {
        var n = self.quad
        return decQuadIsCanonical(&n) == 1
    }
    
    public var isInteger: Bool {
        var n = self.quad
        return decQuadIsInteger(&n) == 1
    }
    
    public var isLittleEndian: Bool { true }
    
    /// Returns the bytes comprising the Decimal128 number in big endian order.
    public var bytes: [UInt8] {
        let data = [decimal.bytes.0,decimal.bytes.1,decimal.bytes.2,decimal.bytes.3,
                    decimal.bytes.4,decimal.bytes.5,decimal.bytes.6,decimal.bytes.7,
                    decimal.bytes.8,decimal.bytes.9,decimal.bytes.10,decimal.bytes.11,
                    decimal.bytes.12,decimal.bytes.13,decimal.bytes.14,decimal.bytes.15]
        return isLittleEndian ? data.reversed() : data
    }
}

extension Decimal128 {
    
    // MARK: - Basic Operations
    
    private init(_ value: decDouble) {
        var d = value
        var q = decQuad()
        decDoubleToWider(&d, &q)
        self.init(q)
    }
    
    /// Removes all trailing zeros without changing the value of the number.
    public func normalize () -> Decimal128 {
        var a = self.quad
        var result = decQuad()
        decQuadReduce(&result, &a, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public var integer : Decimal128 {
        var a = self.quad
        var result = decQuad()
        decQuadToIntegralValue(&result, &a, &Decimal128.context.base, Decimal128.roundMethod)
        return Decimal128(result)
    }
    
    public func remainder (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadRemainderNear(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func negate () -> Decimal128 {
        var a = self.quad
        var result = decQuad()
        decQuadMinus(&result, &a, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func max (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadMax(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func min (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadMin(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public var abs : Decimal128 {
        var a = self.quad
        var result = decQuad()
        decQuadAbs(&result, &a, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func add (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadAdd(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func sub (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadSubtract(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func mul (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadMultiply(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func div (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadDivide(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public func idiv (_ b: Decimal128) -> Decimal128 {
        var b = b.quad
        var a = self.quad
        var result = decQuad()
        decQuadDivideInteger(&result, &a, &b, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    /// Returns *self* + *b* x *c* or multiply accumulate with only the final rounding.
    public func mulAcc (_ b: Decimal128, c: Decimal128) -> Decimal128 {
        var b = b.quad
        var c = c.quad
        var a = self.quad
        var result = decQuad()
        decQuadFMA(&result, &c, &b, &a, &Decimal128.context.base)
        return Decimal128(result)
    }
    
}

extension Decimal128 : Comparable {
    
    // MARK: - Comparable compliance
    
    private static func compare(lhs: Decimal128, rhs: Decimal128) -> Int {
        var lhsd = lhs.quad
        var rhsd = rhs.quad
        var result = decQuad()
        decQuadCompareTotal(&result, &lhsd, &rhsd)
        return Int(decQuadToInt32(&result, &Decimal128.context.base, DecContext.RoundingType.down.value))
    }
    
    public static func < (lhs: Decimal128, rhs: Decimal128) -> Bool {
        compare(lhs: lhs, rhs: rhs) == -1
    }
    
    public static func == (lhs: Decimal128, rhs: Decimal128) -> Bool {
        compare(lhs: lhs, rhs: rhs) == 0
    }
}

extension Decimal128 : Codable {
    
    // MARK: - Archival(Codable) Operations
    enum CodingKeys: String, CodingKey {
        case exponent
        case bcd
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let exp = try values.decode(Int32.self, forKey: .exponent)
        let bcd = try values.decode([UInt8].self, forKey: .bcd)
        var dec = decQuad()
        decQuadFromPacked(&dec, exp, bcd)
        self.init(dec)
    }

    public func encode(to encoder: Encoder) throws {
        var dec = decQuad(bytes: self.decimal.bytes)
        var exponent = decQuadGetExponent(&dec)
        var bcd = [UInt8](repeating: 0, count: Decimal128.maximumDigits/2+1)
        decQuadToPacked(&dec, &exponent, &bcd)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exponent, forKey: .exponent)
        try container.encode(bcd, forKey: .bcd)
    }
}

// MARK: - CustomStringConvertible compliance
// Support the print() command.
extension Decimal128 : CustomStringConvertible {
    public var description : String  {
        var cs = [CChar](repeating: 0, count: Int(DECIMAL128_String))
        var local = decimal
        decimal128ToString(&local, &cs)
        return String(cString: &cs)
    }
}

// MARK: - CustomDebugStringConvertible compliance
extension Decimal128 : CustomDebugStringConvertible {
//    public var debugDescription: String {
//        var str = ""
//        for b in self.bytes {
//            str += String(format: "%02X", b)
//        }
//        return str
//    }
}

extension Decimal128 : Hashable {
    public func hash(into hasher: inout Hasher) {
        self.bytes.forEach { hasher.combine($0) }
    }
}

extension Decimal128 : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
}

extension Decimal128 : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self.init(value) }
}

// Mark: - ExpressibleByStringLiteral compliance
// Allows things like -> a : MGDecimal = "12345"
extension Decimal128 : ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    public init (stringLiteral s: String) { self.init(s)! }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
}

extension Decimal128: LogicalOperations {
    
    var single: decQuad { self.quad }
    
    private func convert (fromBase from: Int, toBase base: Int) -> Decimal128 {
        Utilities.convert(num: self, fromBase: from, toBase: base)
    }
    
    /// converts decimal numbers to logical
    public func logical () -> Decimal128 { abs.convert(fromBase: 10, toBase: 2) }

    /// converts logical numbers to decimal
    public func base10 () -> Decimal128 { convert(fromBase: 2, toBase: 10) }
    
    // MARK: - Compliance to LogicalOperations
    func logical() -> decQuad { self.logical().quad }
    func base10(_ a: decQuad) -> Decimal128 { Decimal128(a).base10() }
    public var zero: decQuad { decQuad() }
    
    func decOr(_ a: UnsafeMutablePointer<decQuad>!, _ b: UnsafePointer<decQuad>!, _ c: UnsafePointer<decQuad>!) {
        decQuadOr(a, b, c, &Decimal128.context.base)
    }

    func decAnd(_ a: UnsafeMutablePointer<decQuad>!, _ b: UnsafePointer<decQuad>!, _ c: UnsafePointer<decQuad>!) {
        decQuadAnd(a, b, c,&Decimal128.context.base)
    }
    
    func decXor(_ a: UnsafeMutablePointer<decQuad>!, _ b: UnsafePointer<decQuad>!, _ c: UnsafePointer<decQuad>!) {
        decQuadXor(a, b, c, &Decimal128.context.base)
    }
    
    func decShift(_ a: UnsafeMutablePointer<decQuad>!, _ b: UnsafePointer<decQuad>!, _ c: UnsafePointer<decQuad>!) {
        decQuadShift(a, b, c, &Decimal128.context.base)
    }
    
    func decRotate(_ a: UnsafeMutablePointer<decQuad>!, _ b: UnsafePointer<decQuad>!, _ c: UnsafePointer<decQuad>!) {
        decQuadRotate(a, b, c, &Decimal128.context.base)
    }
    
    func decInvert(_ a: UnsafeMutablePointer<decQuad>!, _ b: UnsafePointer<decQuad>!) {
        decQuadInvert(a, b, &Decimal128.context.base)
    }
    
    public func decFromString(_ a: UnsafeMutablePointer<decQuad>!, s: String) {
        decQuadFromString(a, s, &Decimal128.context.base)
    }
}

extension Decimal128 : Strideable {
    public func distance(to other: Decimal128) -> Decimal128 { self.sub(other) }
    public func advanced(by n: Decimal128) -> Decimal128 { self.add(n) }
}

extension Decimal128 : AdditiveArithmetic {
    public static func - (lhs: Decimal128, rhs: Decimal128) -> Decimal128 { lhs.sub(rhs) }
    public static func + (lhs: Decimal128, rhs: Decimal128) -> Decimal128 { lhs.add(rhs) }
}

extension Decimal128 : FloatingPoint {
    
    private static func const(_ value: String) -> Decimal128 {
        var result = decimal128()
        decimal128FromString(&result, value, &context.base)
        return Decimal128(result)
    }
    
    public mutating func round(_ rule: FloatingPointRoundingRule) {
        let rounding = Decimal128.context.roundMode // save current setting
        switch rule {
            case .awayFromZero :            Decimal128.context.roundMode = .up
            case .down :                    Decimal128.context.roundMode = .floor
            case .toNearestOrAwayFromZero:  Decimal128.context.roundMode = .halfUp
            case .toNearestOrEven:          Decimal128.context.roundMode = .halfEven
            case .towardZero:               Decimal128.context.roundMode = .down
            case .up:                       Decimal128.context.roundMode = .ceiling
            @unknown default: assert(false, "Unknown rounding rule switch case!")
        }
        var a = self.quad
        var result = decQuad()
        decQuadToIntegralExact(&result, &a, &Decimal128.context.base)
        self = Decimal128(result)
        Decimal128.context.roundMode = rounding  // restore original setting
    }
    
    public static let nan = const("NaN")
    public static let signalingNaN = const("sNaN")
    public static let infinity = const("Infinity")
    
    private static let maxNumber = "9.".padding(toLength: maximumDigits+1, withPad: "9", startingAt: 0)
    private static let minNumber = "0.".padding(toLength: maximumDigits, withPad: "0", startingAt: 0) + "1"
    public static let greatestFiniteMagnitude = const(maxNumber + "E\(DECIMAL128_Emax)")
    public static let leastNormalMagnitude = const(maxNumber + "E\(DECIMAL128_Emin)")
    public static let leastNonzeroMagnitude = const(minNumber + "E\(DECIMAL128_Emin)")
    
    public var ulp: Decimal128 { self.eps }
    public var sign: FloatingPointSign { isNegative ? .minus : .plus }
    
    public var significand: Decimal128 {
        var a = self.quad
        var zero = Decimal128.zero.quad
        var result = decQuad()
        decQuadQuantize(&result, &a, &zero, &Decimal128.context.base)
        return Decimal128(result)
    }
    
    public static func /= (lhs: inout Decimal128, rhs: Decimal128) { lhs = lhs.div(rhs) }
    
    public mutating func formRemainder(dividingBy other: Decimal128) { self = remainder(other) }
    
    public mutating func formTruncatingRemainder(dividingBy other: Decimal128) {
        var b = other.quad
        var a = self.quad
        var result = decQuad()
        decQuadRemainder(&result, &a, &b, &Decimal128.context.base)
        self = Decimal128(result)
    }
    
    public mutating func formSquareRoot() { self = Utilities.root(value: self, n: 2) }
    public mutating func addProduct(_ lhs: Decimal128, _ rhs: Decimal128) { self = self.mulAcc(lhs, c: rhs) }
    
    public var nextUp: Decimal128 {
        var a = self.quad
        var result = decQuad()
        if isNegative {
            decQuadNextPlus(&result, &a, &Decimal128.context.base)
        } else {
            decQuadNextPlus(&result, &a, &Decimal128.context.base)
        }
        return Decimal128(result)
    }
    
    public func isEqual(to other: Decimal128) -> Bool { self == other }
    public func isLess(than other: Decimal128) -> Bool { self < other }
    public func isLessThanOrEqualTo(_ other: Decimal128) -> Bool { Decimal128.compare(lhs: self, rhs: other) <= 0 }
    
    public func isTotallyOrdered(belowOrEqualTo other: Decimal128) -> Bool {
        var b = other.quad
        var a = self.quad
        var result = decQuad()
        decQuadCompareTotalMag(&result, &a, &b)
        let ai = decQuadToInt32(&result, &Decimal128.context.base, DecContext.RoundingType.halfEven.value)
        return ai <= 0
    }
    
    public var isNormal: Bool {
        var b = self.quad
        return decQuadIsNormal(&b) == 1
    }
    
    public var isSignalingNaN: Bool {
        var b = self.quad
        return decQuadIsSignalling(&b) == 1
    }
    
    public init(sign: FloatingPointSign, exponent: Int, significand: Decimal128) {
        var a = significand.quad
        var exp = Decimal128(exponent).quad
        var result = decQuad()
        decQuadScaleB(&result, &a, &exp, &Decimal128.context.base)
        let single = Decimal128(result)
        if sign == .minus {
            decimal = (-single).decimal
        } else {
            decimal = single.decimal
        }
    }
    
    public init(signOf: Decimal128, magnitudeOf: Decimal128) {
        if signOf.isNegative {
            self.init(magnitudeOf.abs.negate())
        } else {
            self.init(magnitudeOf.abs)
        }
    }
    
    public init?<Source>(exactly value: Source) where Source : BinaryInteger { self.init(value) }
    public var magnitude: Decimal128 { self.abs }
    public static func * (lhs: Decimal128, rhs: Decimal128) -> Decimal128 { lhs.mul(rhs) }
    public static func *= (lhs: inout Decimal128, rhs: Decimal128) { lhs = lhs.mul(rhs) }
    
}

extension Decimal128 : Real {
    
    public init(_ value:HDecimal) { self.init(value.decimal) }
    
    // makes the calculations a little neater
    private init(_ value:decNumber) {
        var dv = value
        var d128 = decimal128()
        decimal128FromNumber(&d128, &dv, &Decimal128.context.base)
        self.decimal = d128
    }
    
    private var number:decNumber {
        var xn = decNumber()
        var xd = self.decimal
        decimal128ToNumber(&xd, &xn)
        return xn
    }
    
    // Ok, I cheated and used the decNumber math functions.
    // They are calculated only to correct number of digits for Decimal128 numbers.
    public static func atan2(y: Decimal128, x: Decimal128) -> Decimal128 { Decimal128(Double.atan2(y:y.doubleValue, x:x.doubleValue)) }
    public static func erf(_ x: Decimal128) -> Decimal128 { Decimal128(Double.erf(x.doubleValue)) }
    public static func erfc(_ x: Decimal128) -> Decimal128 { Decimal128(Double.erfc(x.doubleValue)) }
    public static func exp2(_ x: Decimal128) -> Decimal128 { pow(2, x) }
    public static func hypot(_ x: Decimal128, _ y: Decimal128) -> Decimal128 { Decimal128(Double.hypot(x.doubleValue, y.doubleValue)) }
    public static func gamma(_ x: Decimal128) -> Decimal128 { Decimal128(Double.gamma(x.doubleValue)) }
    public static func log2(_ x: Decimal128) -> Decimal128 { log(x)/Decimal128(Utilities.ln2String)! }
    public static func log10(_ x: Decimal128) -> Decimal128 {
        var xn = x.number
        var res = decNumber()
        decNumberLog10(&res, &xn, &Decimal128.context.base)
        return Decimal128(res)
    }
    public static func logGamma(_ x: Decimal128) -> Decimal128 { Decimal128(Double.logGamma(x.doubleValue)) }
    public static func exp(_ x: Decimal128) -> Decimal128 {
        var xn = x.number
        var res = decNumber()
        decNumberExp(&res, &xn, &Decimal128.context.base)
        return Decimal128(res)
    }
    public static func expMinusOne(_ x: Decimal128) -> Decimal128 { Decimal128(Double.expMinusOne(x.doubleValue)) }
    public static func cosh(_ x: Decimal128) -> Decimal128 { Decimal128(Double.cosh(x.doubleValue)) }
    public static func sinh(_ x: Decimal128) -> Decimal128 { Decimal128(Double.sinh(x.doubleValue)) }
    public static func tanh(_ x: Decimal128) -> Decimal128 { Decimal128(Double.tanh(x.doubleValue)) }
    public static func cos(_ x: Decimal128) -> Decimal128 { Decimal128(Double.cos(x.doubleValue)) }
    public static func sin(_ x: Decimal128) -> Decimal128 { Decimal128(Double.sin(x.doubleValue)) }
    public static func tan(_ x: Decimal128) -> Decimal128 { Decimal128(Double.tan(x.doubleValue)) }
    public static func log(_ x: Decimal128) -> Decimal128 {
        var xn = x.number
        var res = decNumber()
        decNumberLn(&res, &xn, &Decimal128.context.base)
        return Decimal128(res)
    }
    public static func log(onePlus x: Decimal128) -> Decimal128 { Decimal128(Double.log(onePlus: x.doubleValue)) }
    public static func acosh(_ x: Decimal128) -> Decimal128 { Decimal128(Double.acosh(x.doubleValue)) }
    public static func asinh(_ x: Decimal128) -> Decimal128 { Decimal128(Double.asinh(x.doubleValue)) }
    public static func atanh(_ x: Decimal128) -> Decimal128 { Decimal128(Double.atanh(x.doubleValue)) }
    public static func acos(_ x: Decimal128) -> Decimal128 { Decimal128(Double.acos(x.doubleValue)) }
    public static func asin(_ x: Decimal128) -> Decimal128 { Decimal128(Double.asin(x.doubleValue)) }
    public static func atan(_ x: Decimal128) -> Decimal128 { Decimal128(Double.atan(x.doubleValue)) }
    public static func pow(_ x: Decimal128, _ y: Decimal128) -> Decimal128 {
        var xn = x.number
        var yn = y.number
        var res = decNumber()
        decNumberPower(&res, &xn, &yn, &Decimal128.context.base)
        return Decimal128(res)
    }
    public static func pow(_ x: Decimal128, _ n: Int) -> Decimal128 { Utilities.power(x, to: n) }
    public static func root(_ x: Decimal128, _ n: Int) -> Decimal128 { Utilities.root(value: x, n: n) }
    public static func factorial(_ x: Decimal128) -> Decimal128 { Utilities.factorial(x) }
}



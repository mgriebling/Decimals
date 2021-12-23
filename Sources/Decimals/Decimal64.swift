
import Foundation
import CDecNumber
import Numerics

///
///  The **Decimal64** struct provides a Swift-based interface to the decNumber C library
///  by Mike Cowlishaw. There are no guarantees of functionality for a given purpose.
///  If you do fix bugs or missing functions, I'd appreciate getting updates of the source.
///
///  The main reason for this library was to provide a decimal-number based datatype
///  that is space-efficient (64 bits) and relatively fast compared to Apple's **Decimal** type.
///  I've also added compliance to the new ``swift_numerics`` _Real_ protocol and provided
///  an instance of the **Complex** generic for **Decimal64**.
///
///  Notes: The maximum **Decimal64** number size is 16 digits with an exponent range
///  from 10⁻³⁸³ to 10⁺³⁸⁴. The endianess is currently hard-coded via
///  ``DECLITEND`` as little-endian.
///
///  Created by Mike Griebling on 17 Dec 2021
///  Copyright © 2021 Computer Inspirations. All rights reserved.
///
public struct Decimal64 {
    
    /// Class properties
    public static let maximumDigits = Int(DECIMAL64_Pmax)
    
    static var context = DecContext(initKind: .dec64)
    
    /// Active angular measurement unit
    public static var angularMeasure = UnitAngle.radians
    
    /// Internal number representation
    fileprivate var decimal = decimal64()
    
    // MARK: - Internal Constants
    public static let pi = Decimal64(Utilities.piString)!
    public static let radix = 10
    public static let π = pi
    public static let zero = Decimal64(0)
    public static let one = Decimal64(1)
    public static let two = Decimal64(2)
    
    // MARK: - Initialization Methods
    public init(_ decimal: Decimal64) { self.decimal = decimal.decimal }
    
    private init(_ number: decimal64) { decimal = number }
    public init(_ value: decDouble)  { decimal.bytes = value.bytes }
    
    public init<Source>(_ value: Source = 0) where Source : BinaryInteger {
        /* small integers (32-bits) are directly convertible */
        if let rint = Int32(exactly: value) {
            // need this to initialize small Ints
            var double = decDouble()
            decDoubleFromInt32(&double, rint)
            self.init(double)
        } else {
            let x: Decimal64 = Utilities.intToReal(value)
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
        let n: Decimal64 = Utilities.doubleToReal(d)
        self.decimal = n.decimal
    }
    
    public init(sign: FloatingPointSign, bcd: [UInt8], exponent: Int) {
        var bcd = bcd
        while bcd.count < Decimal64.maximumDigits { bcd.insert(0, at: 0) }
        var x = decDouble()
        decDoubleSetCoefficient(&x, &bcd, sign == .minus ? 1 : 0)
        decDoubleSetExponent(&x, &Decimal64.context.base, Int32(exponent))
        self.init(x)
    }
    
    // MARK: - Accessor Operations
    
    public var engineeringString : String {
        var cs = [CChar](repeating: 0, count: Int(DECIMAL64_String))
        var local = decimal
        decimal64ToEngString(&local, &cs)
        return String(cString: &cs)
    }
    
    public static var versionString : String { String(cString: decDoubleVersion()) }
    
    /// Returns the type of number (e.g., "NaN", "+Normal", etc.)
    public var numberClass : String {
        var a = self.double
        let cs = decNumberClassToString(decDoubleClass(&a))
        return String(cString: cs!)
    }
    
    public var floatingPointClass: FloatingPointClassification {
        var a = self.double
        let c = decDoubleClass(&a)
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
        var result = [UInt8](repeating: 0, count: Decimal64.maximumDigits)
        var a = self.double
        var exp : Int32 = 0
        decDoubleToBCD(&a, &exp, &result)
        return result
    }
    
    private var double: decDouble { decDouble(bytes: decimal.bytes) }
    
    public var exponent : Int {
        var dec = self.double
        return Int(decDoubleGetExponent(&dec))
    }
    
    public var eps : Decimal64 {
        var local = self.double
        var result = decDouble()
        decDoubleNextPlus(&local, &result, &Decimal64.context.base)
        var result2 = decDouble()
        decDoubleSubtract(&result2, &result, &local, &Decimal64.context.base)
        return Decimal64(result2)
    }
    
    public var isFinite : Bool {
        var n = self.double
        return decDoubleIsFinite(&n) == 1
    }
    
    public var isInfinite: Bool {
        var n = self.double
        return decDoubleIsInfinite(&n) == 1
    }
    
    public var isNaN: Bool {
        var n = self.double
        return decDoubleIsNaN(&n) == 1
    }
    
    public var isNegative: Bool {
        var n = self.double
        return decDoubleIsNegative(&n) == 1
    }
    
    public var isZero: Bool {
        var n = self.double
        return decDoubleIsZero(&n) == 1
    }
    
    public var isSubnormal: Bool {
        var n = self.double
        return decDoubleIsSubnormal(&n) == 1
    }

    public var isCanonical: Bool {
        var n = self.double
        return decDoubleIsCanonical(&n) == 1
    }
    
    public var isInteger: Bool {
        var n = self.double
        return decDoubleIsInteger(&n) == 1
    }
    
    public var isLittleEndian: Bool { true }
    
    /// Returns the bytes comprising the Decimal64 number in big endian order.
    public var bytes: [UInt8] {
        let data = [decimal.bytes.0,decimal.bytes.1,decimal.bytes.2,decimal.bytes.3,
                    decimal.bytes.4,decimal.bytes.5,decimal.bytes.6,decimal.bytes.7]
        return isLittleEndian ? data.reversed() : data
    }
}

extension Decimal64 {
    
    // MARK: - Basic Operations
    
    private init(_ value: decSingle) {
        var s = value
        var d = decDouble()
        decSingleToWider(&s, &d)
        self.init(d)
    }
    
    /// Removes all trailing zeros without changing the value of the number.
    public func normalize () -> Decimal64 {
        var a = self.double
        var result = decDouble()
        decDoubleReduce(&result, &a, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public var integer : Decimal64 {
        var a = self.double
        var result = decDouble()
        decDoubleToIntegralValue(&result, &a, &Decimal64.context.base, Decimal64.roundMethod)
        return Decimal64(result)
    }
    
    public func remainder (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleRemainderNear(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func negate () -> Decimal64 {
        var a = self.double
        var result = decDouble()
        decDoubleMinus(&result, &a, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func max (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleMax(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func min (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleMin(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public var abs : Decimal64 {
        var a = self.double
        var result = decDouble()
        decDoubleAbs(&result, &a, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func add (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleAdd(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func sub (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleSubtract(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func mul (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleMultiply(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func div (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleDivide(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public func idiv (_ b: Decimal64) -> Decimal64 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleDivideInteger(&result, &a, &b, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    /// Returns *self* + *b* x *c* or multiply accumulate with only the final rounding.
    public func mulAcc (_ b: Decimal64, c: Decimal64) -> Decimal64 {
        var b = b.double
        var c = c.double
        var a = self.double
        var result = decDouble()
        decDoubleFMA(&result, &c, &b, &a, &Decimal64.context.base)
        return Decimal64(result)
    }
    
}

extension Decimal64 : Comparable {
    
    // MARK: - Comparable compliance
    
    private static func compare(lhs: Decimal64, rhs: Decimal64) -> Int {
        var lhsd = lhs.double
        var rhsd = rhs.double
        var result = decDouble()
        decDoubleCompareTotal(&result, &lhsd, &rhsd)
        return Int(decDoubleToInt32(&result, &Decimal64.context.base, DecContext.RoundingType.down.value))
    }
    
    public static func < (lhs: Decimal64, rhs: Decimal64) -> Bool {
        compare(lhs: lhs, rhs: rhs) == -1
    }
    
    public static func == (lhs: Decimal64, rhs: Decimal64) -> Bool {
        compare(lhs: lhs, rhs: rhs) == 0
    }
}

extension Decimal64 : Codable {
    
    // MARK: - Archival(Codable) Operations
    enum CodingKeys: String, CodingKey {
        case exponent
        case bcd
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let exp = try values.decode(Int32.self, forKey: .exponent)
        let bcd = try values.decode([UInt8].self, forKey: .bcd)
        var dec = decDouble()
        decDoubleFromPacked(&dec, exp, bcd)
        self.init(dec)
    }

    public func encode(to encoder: Encoder) throws {
        var dec = decDouble(bytes: self.decimal.bytes)
        var exponent = decDoubleGetExponent(&dec)
        var bcd = [UInt8](repeating: 0, count: Decimal64.maximumDigits/2+1)
        decDoubleToPacked(&dec, &exponent, &bcd)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exponent, forKey: .exponent)
        try container.encode(bcd, forKey: .bcd)
    }
}

// MARK: - CustomStringConvertible compliance
// Support the print() command.
extension Decimal64 : CustomStringConvertible {
    public var description : String  {
        var cs = [CChar](repeating: 0, count: Int(DECIMAL64_String))
        var local = decimal
        decimal64ToString(&local, &cs)
        return String(cString: &cs)
    }
}

// MARK: - CustomDebugStringConvertible compliance
extension Decimal64 : CustomDebugStringConvertible {
//    public var debugDescription: String {
//        var str = ""
//        for b in self.bytes {
//            str += String(format: "%02X", b)
//        }
//        return str
//    }
}

extension Decimal64 : Hashable {
    public func hash(into hasher: inout Hasher) {
        self.bytes.forEach { hasher.combine($0) }
    }
}

extension Decimal64 : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
}

extension Decimal64 : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self.init(value) }
}

// Mark: - ExpressibleByStringLiteral compliance
// Allows things like -> a : MGDecimal = "12345"
extension Decimal64 : ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    public init (stringLiteral s: String) { self.init(s)! }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
}

extension Decimal64 : Strideable {
    public func distance(to other: Decimal64) -> Decimal64 { self.sub(other) }
    public func advanced(by n: Decimal64) -> Decimal64 { self.add(n) }
}

extension Decimal64 : AdditiveArithmetic {
    public static func - (lhs: Decimal64, rhs: Decimal64) -> Decimal64 { lhs.sub(rhs) }
    public static func + (lhs: Decimal64, rhs: Decimal64) -> Decimal64 { lhs.add(rhs) }
}

extension Decimal64: LogicalOperations {
    
    var single: decDouble { self.double }
    
    private func convert (fromBase from: Int, toBase base: Int) -> Decimal64 {
        Utilities.convert(num: self, fromBase: from, toBase: base)
    }
    
    /// converts decimal numbers to logical
    public func logical () -> Decimal64 { abs.convert(fromBase: 10, toBase: 2) }

    /// converts logical numbers to decimal
    public func base10 () -> Decimal64 { convert(fromBase: 2, toBase: 10) }
    
    // MARK: - Compliance to LogicalOperations
    func logical() -> decDouble { self.logical().double }
    func base10(_ a: decDouble) -> Decimal64 { Decimal64(a).base10() }
    public var zero: decDouble { decDouble() }
    
    func decOr(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleOr(a, b, c, &Decimal64.context.base)
    }

    func decAnd(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleAnd(a, b, c,&Decimal64.context.base)
    }
    
    func decXor(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleXor(a, b, c, &Decimal64.context.base)
    }
    
    func decShift(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleShift(a, b, c, &Decimal64.context.base)
    }
    
    func decRotate(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleRotate(a, b, c, &Decimal64.context.base)
    }
    
    func decInvert(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!) {
        decDoubleInvert(a, b, &Decimal64.context.base)
    }
    
    public func decFromString(_ a: UnsafeMutablePointer<decDouble>!, s: String) {
        decDoubleFromString(a, s, &Decimal64.context.base)
    }
}

extension Decimal64 : FloatingPoint {
    
    private static func const(_ value: String) -> Decimal64 {
        var result = decimal64()
        decimal64FromString(&result, value, &context.base)
        return Decimal64(result)
    }
    
    public mutating func round(_ rule: FloatingPointRoundingRule) {
        let rounding = Decimal64.context.roundMode // save current setting
        switch rule {
            case .awayFromZero :            Decimal64.context.roundMode = .up
            case .down :                    Decimal64.context.roundMode = .floor
            case .toNearestOrAwayFromZero:  Decimal64.context.roundMode = .halfUp
            case .toNearestOrEven:          Decimal64.context.roundMode = .halfEven
            case .towardZero:               Decimal64.context.roundMode = .down
            case .up:                       Decimal64.context.roundMode = .ceiling
            @unknown default: assert(false, "Unknown rounding rule switch case!")
        }
        var a = self.double
        var result = decDouble()
        decDoubleToIntegralExact(&result, &a, &Decimal64.context.base)
        self = Decimal64(result)
        Decimal64.context.roundMode = rounding  // restore original setting
    }
    
    public static let nan = const("NaN")
    public static let signalingNaN = const("sNaN")
    public static let infinity = const("Infinity")

    private static let maxNumber = "9.".padding(toLength: maximumDigits+1, withPad: "9", startingAt: 0)
    private static let minNumber = "0.".padding(toLength: maximumDigits, withPad: "0", startingAt: 0) + "1"
    public static let greatestFiniteMagnitude = const(maxNumber + "E\(DECIMAL64_Emax)")
    public static let leastNormalMagnitude = const(maxNumber + "E\(DECIMAL64_Emin)")
    public static let leastNonzeroMagnitude = const(minNumber + "E\(DECIMAL64_Emin)")
    
    public var ulp: Decimal64 { self.eps }
    public var sign: FloatingPointSign { isNegative ? .minus : .plus }
    
    public var significand: Decimal64 {
        var a = self.double
        var zero = Decimal64.zero.double
        var result = decDouble()
        decDoubleQuantize(&result, &a, &zero, &Decimal64.context.base)
        return Decimal64(result)
    }
    
    public static func /= (lhs: inout Decimal64, rhs: Decimal64) { lhs = lhs.div(rhs) }
    
    public mutating func formRemainder(dividingBy other: Decimal64) { self = remainder(other) }
    
    public mutating func formTruncatingRemainder(dividingBy other: Decimal64) {
        var b = other.double
        var a = self.double
        var result = decDouble()
        decDoubleRemainder(&result, &a, &b, &Decimal64.context.base)
        self = Decimal64(result)
    }
    
    public mutating func formSquareRoot() { self = Decimal64(Double.sqrt(self.doubleValue)) }
    public mutating func addProduct(_ lhs: Decimal64, _ rhs: Decimal64) { self = self.mulAcc(lhs, c: rhs) }
    
    public var nextUp: Decimal64 {
        var a = self.double
        var result = decDouble()
        if isNegative {
            decDoubleNextPlus(&result, &a, &Decimal64.context.base)
        } else {
            decDoubleNextPlus(&result, &a, &Decimal64.context.base)
        }
        return Decimal64(result)
    }
    
    public func isEqual(to other: Decimal64) -> Bool { self == other }
    public func isLess(than other: Decimal64) -> Bool { self < other }
    public func isLessThanOrEqualTo(_ other: Decimal64) -> Bool { Decimal64.compare(lhs: self, rhs: other) <= 0 }
    
    public func isTotallyOrdered(belowOrEqualTo other: Decimal64) -> Bool {
        var b = other.double
        var a = self.double
        var result = decDouble()
        decDoubleCompareTotalMag(&result, &a, &b)
        let ai = decDoubleToInt32(&result, &Decimal64.context.base, DecContext.RoundingType.halfEven.value)
        return ai <= 0
    }
    
    public var isNormal: Bool {
        var b = self.double
        return decDoubleIsNormal(&b) == 1
    }
    
    public var isSignalingNaN: Bool {
        var b = self.double
        return decDoubleIsSignalling(&b) == 1
    }
    
    public init(sign: FloatingPointSign, exponent: Int, significand: Decimal64) {
        var a = significand.double
        var exp = Decimal64(exponent).double
        var result = decDouble()
        decDoubleScaleB(&result, &a, &exp, &Decimal64.context.base)
        let single = Decimal64(result)
        if sign == .minus {
            decimal = (-single).decimal
        } else {
            decimal = single.decimal
        }
    }
    
    public init(signOf: Decimal64, magnitudeOf: Decimal64) {
        if signOf.isNegative {
            self.init(magnitudeOf.abs.negate())
        } else {
            self.init(magnitudeOf.abs)
        }
    }
    
    public init?<Source>(exactly value: Source) where Source : BinaryInteger { self.init(value) }
    public var magnitude: Decimal64 { self.abs }
    public static func * (lhs: Decimal64, rhs: Decimal64) -> Decimal64 { lhs.mul(rhs) }
    public static func *= (lhs: inout Decimal64, rhs: Decimal64) { lhs = lhs.mul(rhs) }
    
}

extension Decimal64 : Real {
    
    // Ok, I cheated but the Double accuracy is almost enough for these functions.
    // However, feel free to fill these in with decimal-based calculations and please share.
    // On the plus side, the Double calculations are an order of magnitude faster than the Decimal64.
    // Note: Decimal alternatives exist for many of these functions.
    public static func atan2(y: Decimal64, x: Decimal64) -> Decimal64     { Decimal64(Double.atan2(y:y.doubleValue, x:x.doubleValue)) }
    public static func erf(_ x: Decimal64) -> Decimal64                   { Decimal64(Double.erf(x.doubleValue)) }
    public static func erfc(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.erfc(x.doubleValue)) }
    public static func exp2(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.exp2(x.doubleValue)) }
    public static func hypot(_ x: Decimal64, _ y: Decimal64) -> Decimal64 { Decimal64(Double.hypot(x.doubleValue, y.doubleValue)) }
    public static func gamma(_ x: Decimal64) -> Decimal64                 { Decimal64(Double.gamma(x.doubleValue)) }
    public static func log2(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.log2(x.doubleValue)) }
    public static func log10(_ x: Decimal64) -> Decimal64                 { Decimal64(Double.log10(x.doubleValue)) }
    public static func logGamma(_ x: Decimal64) -> Decimal64              { Decimal64(Double.logGamma(x.doubleValue)) }
    public static func exp(_ x: Decimal64) -> Decimal64                   { Decimal64(Double.exp(x.doubleValue)) }
    public static func expMinusOne(_ x: Decimal64) -> Decimal64           { Decimal64(Double.expMinusOne(x.doubleValue)) }
    public static func cosh(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.cosh(x.doubleValue)) }
    public static func sinh(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.sinh(x.doubleValue)) }
    public static func tanh(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.tanh(x.doubleValue)) }
    public static func cos(_ x: Decimal64) -> Decimal64                   { Decimal64(Double.cos(x.doubleValue)) }
    public static func sin(_ x: Decimal64) -> Decimal64                   { Decimal64(Double.sin(x.doubleValue)) }
    public static func tan(_ x: Decimal64) -> Decimal64                   { Decimal64(Double.tan(x.doubleValue)) }
    public static func log(_ x: Decimal64) -> Decimal64                   { Decimal64(Double.log(x.doubleValue)) }
    public static func log(onePlus x: Decimal64) -> Decimal64             { Decimal64(Double.log(onePlus: x.doubleValue)) }
    public static func acosh(_ x: Decimal64) -> Decimal64                 { Decimal64(Double.acosh(x.doubleValue)) }
    public static func asinh(_ x: Decimal64) -> Decimal64                 { Decimal64(Double.asinh(x.doubleValue)) }
    public static func atanh(_ x: Decimal64) -> Decimal64                 { Decimal64(Double.atanh(x.doubleValue)) }
    public static func acos(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.acos(x.doubleValue)) }
    public static func asin(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.asin(x.doubleValue)) }
    public static func atan(_ x: Decimal64) -> Decimal64                  { Decimal64(Double.atan(x.doubleValue)) }
    public static func pow(_ x: Decimal64, _ y: Decimal64) -> Decimal64   { Decimal64(Double.pow(x.doubleValue, y.doubleValue)) }
    public static func pow(_ x: Decimal64, _ n: Int) -> Decimal64         { Decimal64(Double.pow(x.doubleValue, n)) }
    public static func root(_ x: Decimal64, _ n: Int) -> Decimal64        { Decimal64(Double.root(x.doubleValue, n)) }
    
    public static func factorial(_ x: Decimal64) -> Decimal64 { Utilities.factorial(x) }
}


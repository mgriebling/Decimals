import Foundation
import CDecNumber
import Numerics

///
///  The **Decimal32** struct provides a Swift-based interface to the decNumber C library
///  by Mike Cowlishaw. There are no guarantees of functionality for a given purpose.
///  If you do fix bugs or missing functions, I'd appreciate getting updates of the source.
///
///  The main reason for this library was to provide a decimal-number based datatype
///  that is space-efficient (32 bits) and relatively fast compared to Apple's **Decimal** type.
///  I've also added compliance to the new ``swift_numerics`` _Real_ protocol and provided
///  an instance of the **Complex** generic for **Decimal32**.
///
///  Notes: The maximum **Decimal32** number size is 7 digits with an exponent range
///  from 10⁻⁹⁵ to 10⁺⁹⁶. The endianess is currently hard-coded via
///  ``DECLITEND`` as little-endian.
///
///  Created by Mike Griebling on 4 Dec 2021
///  Copyright © 2021 Computer Inspirations. All rights reserved.
///
public struct Decimal32 {
    
    /// Class properties
    public static let maximumDigits = Int(DECIMAL32_Pmax)

    static var context = DecContext(initKind: .dec32)
    
    /// Active angular measurement unit
    public static var angularMeasure = UnitAngle.radians
    
    /// Internal number representation
    fileprivate var decimal = decimal32()
    
    // MARK: - Internal Constants
    public static let pi = Decimal32(Double.pi)
    public static let radix = 10
    public static let π = pi
    public static let zero = Decimal32(0)
    public static let one = Decimal32(1)
    public static let two = Decimal32(2)
    
    // MARK: - Initialization Methods
    public init(_ decimal: Decimal32) { self.decimal = decimal.decimal }
    
    private init(_ number: decimal32) { decimal = number }
    public init(_ value: decSingle)  { decimal.bytes = value.bytes }
    
    public init<Source>(_ value: Source = 0) where Source : BinaryInteger {
        /* small integers (32-bits) are directly convertible */
        if let rint = Int32(exactly: value) {
            // need this to initialize small Ints
            var double = decDouble()
            decDoubleFromInt32(&double, rint)
            self.init(double)
        } else {
            let x: Decimal32 = Utilities.intToReal(value)
            self.init(x)
        }
    }
    
    public init?(_ s: String, radix: Int = 10) {
        if let x = numberFromString(s, digits: 0, radix: radix) {
            decimal = x.decimal; return
        }
        return nil
    }
    
    public init(sign: FloatingPointSign, bcd: [UInt8], exponent: Int) {
        var bcd = bcd
        while bcd.count < Decimal32.maximumDigits { bcd.insert(0, at: 0) }
        var x = decSingle()
        decSingleSetCoefficient(&x, &bcd, sign == .minus ? 1 : 0)
        decSingleSetExponent(&x, &Decimal32.context.base, Int32(exponent))
        self.init(x)
    }
    
    public init(_ d: Double) {
        // we cheat by first converting to a string since Double conversions aren't accurate anyway
        let n: Decimal32 = Utilities.doubleToReal(d)
        self.decimal = n.decimal
    }
    
    // MARK: - Accessor Operations
    
    public var engineeringString : String {
        var cs = [CChar](repeating: 0, count: Int(DECIMAL32_String))
        var local = decimal
        decimal32ToEngString(&local, &cs)
        return String(cString: &cs)
    }
    
    public static var versionString : String { String(cString: decSingleVersion()) }
    
    /// Returns the type of number (e.g., "NaN", "+Normal", etc.)
    public var numberClass : String {
        var a = self.double
        let cs = decNumberClassToString(decDoubleClass(&a))
        return String(cString: cs!)
    }
    
    public static var roundMethod : rounding {
        get { decContextGetRounding(&context.base) }
        set { decContextSetRounding(&context.base, newValue) }
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
    
    /// Returns all digits of the binary-coded decimal (BCD) digits of the number with
    /// one value (0 to 9) per byte. The exponent can be obtained via _exponent_.
    public var bcd : [UInt8] {
        var result = [UInt8](repeating: 0, count: Decimal32.maximumDigits)
        var a = self.single
        decSingleGetCoefficient(&a, &result)
        return result
    }
    
    public var single: decSingle { decSingle(bytes: decimal.bytes) }
    
    private var double: decDouble {
        var source = single
        var destination = decDouble()
        decSingleToWider(&source, &destination)
        return destination
    }
    
    public var exponent : Int {
        var dec = self.single
        return Int(decSingleGetExponent(&dec))
    }
    
    public var eps : Decimal32 {
        var local = self.double
        var result = decDouble()
        decDoubleNextPlus(&local, &result, &Decimal32.context.base)
        var result2 = decDouble()
        decDoubleSubtract(&result2, &result, &local, &Decimal32.context.base)
        var single = decSingle()
        decSingleFromWider(&single, &result2, &Decimal32.context.base)
        return Decimal32(single)
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
    
    /// Returns the bytes comprising the Decimal32 number in big endian order.
    public var bytes: [UInt8] {
        let data = [decimal.bytes.0,decimal.bytes.1,decimal.bytes.2,decimal.bytes.3]
        return isLittleEndian ? data.reversed() : data
    }
}

extension Decimal32 {
    
    // MARK: - Basic Operations
    
    internal init(_ value: decDouble) {
        var d = value
        var s = decSingle()
        decSingleFromWider(&s, &d, &Decimal32.context.base)
        self.init(s)
    }
    
    /// Removes all trailing zeros without changing the value of the number.
    public func normalize () -> Decimal32 {
        var a = self.double
        var result = decDouble()
        decDoubleReduce(&result, &a, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public var integer : Decimal32 {
        var a = self.double
        var result = decDouble()
        decDoubleToIntegralValue(&result, &a, &Decimal32.context.base, Decimal32.roundMethod)
        return Decimal32(result)
    }
    
    public func remainder (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleRemainderNear(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func negate () -> Decimal32 {
        var a = self.double
        var result = decDouble()
        decDoubleMinus(&result, &a, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func max (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleMax(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func min (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleMin(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public var abs : Decimal32 {
        var a = self.double
        var result = decDouble()
        decDoubleAbs(&result, &a, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func add (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleAdd(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func sub (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleSubtract(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func mul (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleMultiply(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func div (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleDivide(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public func idiv (_ b: Decimal32) -> Decimal32 {
        var b = b.double
        var a = self.double
        var result = decDouble()
        decDoubleDivideInteger(&result, &a, &b, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    /// Returns *self* + *b* x *c* or multiply accumulate with only the final rounding.
    public func mulAcc (_ b: Decimal32, c: Decimal32) -> Decimal32 {
        var b = b.double
        var c = c.double
        var a = self.double
        var result = decDouble()
        decDoubleFMA(&result, &c, &b, &a, &Decimal32.context.base)
        return Decimal32(result)
    }
    
}

extension Decimal32 : Comparable {
    
    // MARK: - Comparable compliance
    
    private static func compare(lhs: Decimal32, rhs: Decimal32) -> Int {
        var lhsd = lhs.double
        var rhsd = rhs.double
        var result = decDouble()
        decDoubleCompareTotal(&result, &lhsd, &rhsd)
        return Int(decDoubleToInt32(&result, &Decimal64.context.base, DecContext.RoundingType.down.value))
    }
    
    public static func < (lhs: Decimal32, rhs: Decimal32) -> Bool {
        compare(lhs: lhs, rhs: rhs) == -1
    }
    
    public static func == (lhs: Decimal32, rhs: Decimal32) -> Bool {
        compare(lhs: lhs, rhs: rhs) == 0
    }
}

extension Decimal32 : Codable {
    
    // MARK: - Archival(Codable) Operations
    enum CodingKeys: String, CodingKey {
        case exponent
        case bcd
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let exp = try values.decode(Int32.self, forKey: .exponent)
        let bcd = try values.decode([UInt8].self, forKey: .bcd)
        var dec = decSingle()
        decSingleFromPacked(&dec, exp, bcd)
        self.init(dec)
    }

    public func encode(to encoder: Encoder) throws {
        var dec = decSingle(bytes: self.decimal.bytes)
        var exponent = decSingleGetExponent(&dec)
        var bcd = [UInt8](repeating: 0, count: Decimal32.maximumDigits/2+1)
        decSingleToPacked(&dec, &exponent, &bcd)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exponent, forKey: .exponent)
        try container.encode(bcd, forKey: .bcd)
    }
}

// MARK: - CustomStringConvertible compliance
// Support the print() command.
extension Decimal32 : CustomStringConvertible {
    public var description : String  {
        var cs = [CChar](repeating: 0, count: Int(DECIMAL32_String))
        var local = decimal
        decimal32ToString(&local, &cs)
        return String(cString: &cs)
    }
}

// MARK: - CustomDebugStringConvertible compliance
extension Decimal32 : CustomDebugStringConvertible { }

extension Decimal32 : Hashable {
    public func hash(into hasher: inout Hasher) {
        self.bytes.forEach { hasher.combine($0) }
    }
}

extension Decimal32 : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
}

extension Decimal32 : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self.init(value) }
}

// Mark: - ExpressibleByStringLiteral compliance
// Allows things like -> a : MGDecimal = "12345"
extension Decimal32 : ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    public init (stringLiteral s: String) { self.init(s)! }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
}

extension Decimal32: LogicalOperations {

    private func convert (fromBase from: Int, toBase base: Int) -> Decimal32 {
        Utilities.convert(num: self, fromBase: from, toBase: base)
    }
    
    /// converts decimal numbers to logical
    public func logical () -> Decimal32 { abs.convert(fromBase: 10, toBase: 2) }

    /// converts logical numbers to decimal
    public func base10 () -> Decimal32 { convert(fromBase: 2, toBase: 10) }
    
    // MARK: - Compliance to LogicalOperations
    func logical() -> decDouble { self.logical().double }
    func base10(_ a: decDouble) -> Decimal32 { Decimal32(a).base10() }
    public var zero: decDouble { decDouble() }
    
    func decOr(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleOr(a, b, c, &Decimal32.context.base)
    }

    func decAnd(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleAnd(a, b, c,&Decimal32.context.base)
    }
    
    func decXor(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleXor(a, b, c, &Decimal32.context.base)
    }
    
    func decShift(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleShift(a, b, c, &Decimal32.context.base)
    }
    
    func decRotate(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!, _ c: UnsafePointer<decDouble>!) {
        decDoubleRotate(a, b, c, &Decimal32.context.base)
    }
    
    func decInvert(_ a: UnsafeMutablePointer<decDouble>!, _ b: UnsafePointer<decDouble>!) {
        decDoubleInvert(a, b, &Decimal32.context.base)
    }
    
    public func decFromString(_ a: UnsafeMutablePointer<decSingle>!, s: String) {
        decSingleFromString(a, s, &Decimal32.context.base)
    }
}

extension Decimal32 : Strideable {
    public func distance(to other: Decimal32) -> Decimal32 { self.sub(other) }
    public func advanced(by n: Decimal32) -> Decimal32 { self.add(n) }
}

extension Decimal32 : AdditiveArithmetic {
    public static func - (lhs: Decimal32, rhs: Decimal32) -> Decimal32 { lhs.sub(rhs) }
    public static func + (lhs: Decimal32, rhs: Decimal32) -> Decimal32 { lhs.add(rhs) }
}

extension Decimal32 : FloatingPoint {
 
    public mutating func round(_ rule: FloatingPointRoundingRule) {
        let rounding = Decimal32.context.roundMode // save current setting
        switch rule {
            case .awayFromZero :            Decimal32.context.roundMode = .up
            case .down :                    Decimal32.context.roundMode = .floor
            case .toNearestOrAwayFromZero:  Decimal32.context.roundMode = .halfUp
            case .toNearestOrEven:          Decimal32.context.roundMode = .halfEven
            case .towardZero:               Decimal32.context.roundMode = .down
            case .up:                       Decimal32.context.roundMode = .ceiling
            @unknown default: assert(false, "Unknown rounding rule switch case!")
        }
        var a = self.double
        var result = decDouble()
        var b = decSingle()
        decDoubleToIntegralExact(&result, &a, &Decimal32.context.base)
        decSingleFromWider(&b, &result, &Decimal32.context.base)
        self = Decimal32(b)
        Decimal32.context.roundMode = rounding  // restore original setting
    }
    
    private static func const(_ value: String) -> Decimal32 {
        var result = decimal32()
        decimal32FromString(&result, value, &context.base)
        return Decimal32(result)
    }
    
    public static let nan = const("NaN")
    public static let signalingNaN = const("sNaN")
    public static let infinity = const("Infinity")
    private static let maxNumber = "9.".padding(toLength: maximumDigits+1, withPad: "9", startingAt: 0)
    private static let minNumber = "0.".padding(toLength: maximumDigits, withPad: "0", startingAt: 0) + "1"
    public static let greatestFiniteMagnitude = const(maxNumber + "E\(DECIMAL32_Emax)")
    public static let leastNormalMagnitude = const(maxNumber + "E\(DECIMAL32_Emin)")
    public static let leastNonzeroMagnitude = const(minNumber + "E\(DECIMAL32_Emin)")
    
    public var ulp: Decimal32 { self.eps }
    public var sign: FloatingPointSign { isNegative ? .minus : .plus }
    
    public var significand: Decimal32 {
        var a = self.double
        var zero = Decimal32.zero.double
        var result = decDouble()
        decDoubleQuantize(&result, &a, &zero, &Decimal32.context.base)
        return Decimal32(result)
    }
    
    public mutating func formRemainder(dividingBy other: Decimal32) { self = remainder(other) }
    
    public mutating func formTruncatingRemainder(dividingBy other: Decimal32) {
        var b = other.double
        var a = self.double
        var result = decDouble()
        decDoubleRemainder(&result, &a, &b, &Decimal32.context.base)
        self = Decimal32(result)
    }
    
    public mutating func formSquareRoot() { self = Decimal32(Double.sqrt(self.doubleValue)) }
    public mutating func addProduct(_ lhs: Decimal32, _ rhs: Decimal32) { self = self.mulAcc(lhs, c: rhs) }
    
    public var nextUp: Decimal32 {
        var a = self.double
        var result = decDouble()
        let digits = Decimal32.context.digits
        let round = Decimal32.context.roundMode
        print(digits, round)
        if isNegative {
            decDoubleNextMinus(&result, &a, &Decimal32.context.base)
        } else {
            decDoubleNextPlus(&result, &a, &Decimal32.context.base)
        }
        return Decimal32(result)
    }
    
    public func isEqual(to other: Decimal32) -> Bool { self == other }
    public func isLess(than other: Decimal32) -> Bool { self < other }
    public func isLessThanOrEqualTo(_ other: Decimal32) -> Bool { Decimal32.compare(lhs: self, rhs: other) <= 0 }
    
    public func isTotallyOrdered(belowOrEqualTo other: Decimal32) -> Bool {
        var b = other.double
        var a = self.double
        var result = decDouble()
        decDoubleCompareTotalMag(&result, &a, &b)
        let ai = decDoubleToInt32(&result, &Decimal32.context.base, DecContext.RoundingType.halfEven.value)
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
    
    public init(sign: FloatingPointSign, exponent: Int, significand: Decimal32) {
        var a = significand.double
        var exp = Decimal32(exponent).double
        var result = decDouble()
        decDoubleScaleB(&result, &a, &exp, &Decimal32.context.base)
        let single = Decimal32(result)
        if sign == .minus {
            decimal = (-single).decimal
        } else {
            decimal = single.decimal
        }
    }
    
    public init(signOf: Decimal32, magnitudeOf: Decimal32) {
        if signOf.isNegative {
            self.init(magnitudeOf.abs.negate())
        } else {
            self.init(magnitudeOf.abs)
        }
    }
    
    public init?<Source>(exactly value: Source) where Source : BinaryInteger { self.init(value) }
    public var magnitude: Decimal32 { self.abs }
    public static func * (lhs: Decimal32, rhs: Decimal32) -> Decimal32 { lhs.mul(rhs) }
    public static func *= (lhs: inout Decimal32, rhs: Decimal32) { lhs = lhs.mul(rhs) }
    
}

extension Decimal32 : Real {
    
    // Ok, I cheated but the Double accuracy should be more than enough for these functions.
    // Since, they are hardware accelerated, the Double calculations are much faster than software-based Decimal32.
    public static func atan2(y: Decimal32, x: Decimal32) -> Decimal32 { Decimal32(Double.atan2(y:y.doubleValue, x:x.doubleValue)) }
    public static func erf(_ x: Decimal32) -> Decimal32 { Decimal32(Double.erf(x.doubleValue)) }
    public static func erfc(_ x: Decimal32) -> Decimal32 { Decimal32(Double.erfc(x.doubleValue)) }
    public static func exp2(_ x: Decimal32) -> Decimal32 { Decimal32(Double.exp2(x.doubleValue)) }
    public static func hypot(_ x: Decimal32, _ y: Decimal32) -> Decimal32 { Decimal32(Double.hypot(x.doubleValue, y.doubleValue)) }
    public static func gamma(_ x: Decimal32) -> Decimal32 { Decimal32(Double.gamma(x.doubleValue)) }
    public static func log2(_ x: Decimal32) -> Decimal32 { Decimal32(Double.log2(x.doubleValue)) }
    public static func log10(_ x: Decimal32) -> Decimal32 { Decimal32(Double.log10(x.doubleValue)) }
    public static func logGamma(_ x: Decimal32) -> Decimal32 { Decimal32(Double.logGamma(x.doubleValue)) }
    public static func exp(_ x: Decimal32) -> Decimal32 { Decimal32(Double.exp(x.doubleValue)) }
    public static func expMinusOne(_ x: Decimal32) -> Decimal32 { Decimal32(Double.expMinusOne(x.doubleValue)) }
    public static func cosh(_ x: Decimal32) -> Decimal32 { Decimal32(Double.cosh(x.doubleValue)) }
    public static func sinh(_ x: Decimal32) -> Decimal32 { Decimal32(Double.sinh(x.doubleValue)) }
    public static func tanh(_ x: Decimal32) -> Decimal32 { Decimal32(Double.tanh(x.doubleValue)) }
    public static func cos(_ x: Decimal32) -> Decimal32 { Decimal32(Double.cos(x.doubleValue)) }
    public static func sin(_ x: Decimal32) -> Decimal32 { Decimal32(Double.sin(x.doubleValue)) }
    public static func tan(_ x: Decimal32) -> Decimal32 { Decimal32(Double.tan(x.doubleValue)) }
    public static func log(_ x: Decimal32) -> Decimal32 { Decimal32(Double.log(x.doubleValue)) }
    public static func log(onePlus x: Decimal32) -> Decimal32 { Decimal32(Double.log(onePlus: x.doubleValue)) }
    public static func acosh(_ x: Decimal32) -> Decimal32 { Decimal32(Double.acosh(x.doubleValue)) }
    public static func asinh(_ x: Decimal32) -> Decimal32 { Decimal32(Double.asinh(x.doubleValue)) }
    public static func atanh(_ x: Decimal32) -> Decimal32 { Decimal32(Double.atanh(x.doubleValue)) }
    public static func acos(_ x: Decimal32) -> Decimal32 { Decimal32(Double.acos(x.doubleValue)) }
    public static func asin(_ x: Decimal32) -> Decimal32 { Decimal32(Double.asin(x.doubleValue)) }
    public static func atan(_ x: Decimal32) -> Decimal32 { Decimal32(Double.atan(x.doubleValue)) }
    public static func pow(_ x: Decimal32, _ y: Decimal32) -> Decimal32 { Decimal32(Double.pow(x.doubleValue, y.doubleValue)) }
    public static func pow(_ x: Decimal32, _ n: Int) -> Decimal32 { Decimal32(Double.pow(x.doubleValue, n)) }
    public static func root(_ x: Decimal32, _ n: Int) -> Decimal32 { Decimal32(Double.root(x.doubleValue, n)) }
    
    public static func factorial(_ x: Decimal32) -> Decimal32 { Utilities.factorial(x) }
}



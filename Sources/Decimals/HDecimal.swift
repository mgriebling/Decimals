import Foundation
import CDecNumber
import Numerics

///
///  The HDecimal struct provides a Swift-based interface to the decNumber C library
///  by Mike Cowlishaw. There are no guarantees of functionality for a given purpose.
///  If you do fix bugs or missing functions, I'd appreciate getting updates of the source.
///
///  The main reason for this library was to provide an alternative to Apple's Decimal
///  library which has limited functionality and is restricted to only 38 digits.  I
///  have provided a rudimentary conversion from the Decimal type to the HDecimal.
///  They are otherwise not compatible.
///
///  Notes: The maximum decimal number size is currently hard-limited to 128 digits
///  via DECNUMDIGITS.  The number of digits per exponent is fixed at six to allow
///  mathematical functions to work. The endianess is currently hard-carded via
///  DECLITEND as little-endian.
///
///  Created by Mike Griebling on 4 Sep 2015.
///  Copyright © 2015-2021 Computer Inspirations. All rights reserved.
///

public struct HDecimal {
    
    /// Class properties
    public static let maximumDigits = Int(DECNUMDIGITS)
    public static let maximumExponent = 999999999        // maximum adjusted exponent ditto
    public static let minimumExponent = -maximumExponent // minimum adjusted exponent ditto
    public static let nominalDigits = 38                 // number of decimal digits in Apple's Decimal type
    
    static public private(set) var context: DecContext = {
        print("Setting the context")
        return DecContext(initKind: .base)
    }()
    
    /// Active angular measurement unit
    public static var angularMeasure = UnitAngle.radians
    
    /// Internal number representation
    fileprivate(set) var decimal = decNumber()
    
    private func initContext(digits: Int) {
        HDecimal.context.digits = digits
//        HDecimal.context.status = .clearFlags
        HDecimal.context.base.traps = 0
    }
    
    // MARK: - Internal Constants
    public static let pi = HDecimal(Utilities.piString, digits: maximumDigits)!
    public static let ln2 = HDecimal(Utilities.ln2String, digits: maximumDigits)!
    
    public static let π = pi
    public static let zero = HDecimal(0)
    public static let one = HDecimal(1)
    public static let two = HDecimal(2)
    
    public static var infinity : HDecimal { var x = zero; x.setINF(); return x }
    fileprivate static var Nil : HDecimal?
    public static var NaN : HDecimal { var x = zero; x.setNAN(); return x }
    public static var sNaN : HDecimal { var x = zero; x.setsNAN(); return x }
    fileprivate static let _2pi = two * pi
    fileprivate static let pi_2 = pi / two
    
    private static let maxNumber = "9.".padding(toLength: maximumDigits+1, withPad: "9", startingAt: 0)
    private static let minNumber = "0.".padding(toLength: maximumDigits, withPad: "0", startingAt: 0) + "1"
    public static let greatestFiniteMagnitude = HDecimal(maxNumber + "E\(maximumExponent)", digits: maximumDigits)!
    public static let leastNormalMagnitude = HDecimal(maxNumber + "E\(minimumExponent)", digits: maximumDigits)!
    public static let leastNonzeroMagnitude = HDecimal(minNumber + "E\(minimumExponent)", digits: maximumDigits)!
    
    /// Takes into account infinity and NaN
    public func isTotallyOrdered(belowOrEqualTo other: HDecimal) -> Bool {
        var b = other
        var a = decimal
        var result = decNumber()
        decNumberCompareTotalMag(&result, &a, &b.decimal, &HDecimal.context.base)
        let ai = decNumberToInt32(&result, &HDecimal.context.base)
        return ai <= 0
    }
    
    public static let radix = 10
    
    // MARK: - Status Methods
    
    public static var errorString : String { context.statusString }
    
    public static func clearStatus() { context.status = .clearFlags }
    
    public static var roundMethod : DecContext.RoundingType {
        get { context.roundMode }
        set { context.roundMode = newValue }
    }
    
    public static var digits : Int {
        get { context.digits }
        set { context.digits = newValue }
    }
    
    // Returns the next smallest increment toward *+infinity*.
    public var nextUp: HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberNextPlus(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    // Returns the next smallest increment toward *-infinity*.
    public var nextDown: HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberNextMinus(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns the next smallest increment from *self* toward *n*.
    public func nextToward(_ n: HDecimal) -> HDecimal {
        var a = decimal
        var n = n.decimal
        var result = decNumber()
        decNumberNextToward(&result, &a, &n, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Return true if the exponents of *self* and *n* are the same.
    public func sameQuantum(_ n: HDecimal) -> Bool {
        var a = decimal
        var n = n.decimal
        var result = decNumber()
        decNumberSameQuantum(&result, &a, &n)
        return !HDecimal(result).isZero
    }
    
    /// Returns *self* with the exponent set to *n*'s exponent.
    public func quantize(_ n: HDecimal) -> HDecimal {
        var a = decimal
        var n = n.decimal
        var result = decNumber()
        decNumberQuantize(&result, &a, &n, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns a *normalized* version of *self* with the shortest
    /// possible form.
    public var reduce: HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberReduce(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns *self* scaled by *n* decimal places where
    /// *n* must be an integral number with no more than nine digits.
    public func rescale(_ n: HDecimal) -> HDecimal {
        var a = decimal
        var n = n.decimal
        var result = decNumber()
        decNumberRescale(&result, &a, &n, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns a version of *self* with trailing fractional zeros removed.
    public var trim: HDecimal {
        var a = decimal
        decNumberTrim(&a)
        return HDecimal(a)
    }
    
    public mutating func round(_ rule: FloatingPointRoundingRule) {
        let rounding = HDecimal.roundMethod // save current setting
        switch rule {
            case .awayFromZero :            HDecimal.context.roundMode = .up
            case .down :                    HDecimal.context.roundMode = .floor
            case .toNearestOrAwayFromZero:  HDecimal.context.roundMode = .halfUp
            case .toNearestOrEven:          HDecimal.context.roundMode = .halfEven
            case .towardZero:               HDecimal.context.roundMode = .down
            case .up:                       HDecimal.context.roundMode = .ceiling
            @unknown default: assert(false, "Unknown rounding rule switch case!")
        }
        var a = decimal
        var result = decNumber()
        decNumberToIntegralValue(&result, &a, &HDecimal.context.base)
        decimal = result
        HDecimal.roundMethod = rounding  // restore original setting
    }
    
    public var significand: HDecimal {
        var a = decimal
        var zero = HDecimal.zero.decimal
        var result = decNumber()
        decNumberRescale(&result, &a, &zero, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public mutating func formRemainder(dividingBy other: HDecimal) {
        var a = decimal
        var b = other.decimal
        var result = decNumber()
        decNumberRemainderNear(&result, &a, &b, &HDecimal.context.base)
        decimal = result
    }
    
    public mutating func formTruncatingRemainder(dividingBy other: HDecimal) {
        var a = decimal
        var b = other.decimal
        var result = decNumber()
        decNumberRemainder(&result, &a, &b, &HDecimal.context.base)
        decimal = result
    }
    
    // MARK: - Initialization Methods
    
    public init(_ decimal : HDecimal) { initContext(digits: HDecimal.context.digits); self.decimal = decimal.decimal }
    
    public init<Source>(_ value: Source = 0) where Source : BinaryInteger {
        /* small integers (32-bits) are directly convertible */
        initContext(digits: HDecimal.context.digits)
        if let rint = Int32(exactly: value) {
            // need this to initialize small Ints
            decNumberFromInt32(&decimal, rint)
        } else {
            let x: HDecimal = Utilities.intToReal(value)
            decimal = x.decimal
        }
    }
    
    public init(_ d: Double) {
        initContext(digits:  HDecimal.context.digits)
        let n: HDecimal = Utilities.doubleToReal(d)
        self.decimal = n.decimal
    }
    
    public init(sign: FloatingPointSign, exponent: Int, significand: HDecimal) {
        initContext(digits:  HDecimal.context.digits)
        var a = significand
        var exp = HDecimal(exponent)
        var result = decNumber()
        decNumberRescale(&result, &a.decimal, &exp.decimal, &HDecimal.context.base)
        if sign == .minus {
            decNumberCopyNegate(&decimal, &result)
        } else {
            decimal = result
        }
    }
    
    public init(signOf: HDecimal, magnitudeOf: HDecimal) {
        initContext(digits:  HDecimal.context.digits)
        var result = decNumber()
        var a = magnitudeOf.decimal
        var sign = signOf.decimal
        decNumberCopySign(&result, &a, &sign)
        decimal = result
    }
    
    public init(_ decimal: Foundation.Decimal) {
        // we cheat since this should be an uncommon thing to do
        let numStr = decimal.description
        self.init(numStr, digits: HDecimal.context.digits)!  // Apple Decimals are 38 digits fixed
    }
    
    public init?(_ s: String, radix: Int) { self.init(s, digits: 0, radix: radix) }
    
    public init?(_ s: String, digits: Int = 0, radix: Int = 10) {
        let digits = digits == 0 ? (HDecimal.digits == 0 ? HDecimal.nominalDigits : HDecimal.digits) : digits
        initContext(digits: digits)
        if let x = numberFromString(s, digits: digits, radix: radix) {
            decimal = x.decimal; return
        }
        decimal = HDecimal.nan.decimal
    }
    
    public func decFromString(_ a: UnsafeMutablePointer<decNumber>!, s: String) {
        decNumberFromString(a, s, &HDecimal.context.base)
//        if !HDecimal.context.status.isEmpty { print("ERROR: \(HDecimal.context.status)") }
//        HDecimal.context.status = .clearFlags
    }
    
    public init(sign: FloatingPointSign, bcd: [UInt8], exponent: Int) {
        var bcd = bcd
        initContext(digits: HDecimal.context.digits)
        decimal.digits = Int32(HDecimal.context.digits)
        decNumberSetBCD(&decimal, &bcd, UInt32(decimal.digits))
        var exp = decNumber()
        decNumberFromInt32(&exp, Int32(exponent))
        var result = decNumber()
        decNumberScaleB(&result, &decimal, &exp, &HDecimal.context.base)
        decimal = result
    }
    
    public init(_ d: decNumber) {
        initContext(digits: HDecimal.context.digits)
        decimal = d
    }
    
    // MARK: - Accessor Operations 
    
    public var engineeringString : String {
        var cs = [CChar](repeating: 0, count: Int(decimal.digits+14))
        var local = decimal
        decNumberToEngString(&local, &cs)
        return String(cString: &cs)
    }
    
    static private let radixDigits = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static private let miniDigits = Array("₀₁₂₃₄₅₆₇₈₉")
    
    private func getRadixDigitFor(_ n: Int) -> String { String(HDecimal.radixDigits[n]) }
    
    private func getMiniRadixDigits(_ radix: Int) -> String {
        var result = ""
        var radix = radix
        while radix > 0 {
            let offset = radix % 10; radix /= 10
            let digit = HDecimal.miniDigits[offset]
            result = String(digit) + result
        }
        return result
    }
    
    private func convert (fromBase from: Int, toBase base: Int) -> HDecimal {
        if self.isSpecial || from == base { return self }  // ensure NaNs are propagated
        let oldDigits = HDecimal.digits
        HDecimal.digits = HDecimal.maximumDigits
        let y = Utilities.convert(num: self, fromBase: from, toBase: base)
        HDecimal.digits = oldDigits
        return y
    }
    
    public func string(withRadix radix: Int, showBase: Bool = false, showSign: Bool = false) -> String {
        if self.isSpecial || self.isZero { return self.description }
        var n = self.integer.abs
        
        // restrict to legal radix values 2 to 36
        let dradix = HDecimal(Swift.min(36, Swift.max(radix, 2)))
        var str = ""
        while !n.isZero {
            let digit = n % dradix
            n = n.idiv(dradix)
            str = getRadixDigitFor(digit.int) + str
        }
        if showBase { str += getMiniRadixDigits(radix) }
        return showSign && self.isNegative ? "-" + str : str
    }
    
    public static var versionString : String { String(cString: decNumberVersion()) }
    
    /// Returns the type of number (e.g., "NaN", "+Normal", etc.)
    public var numberClass : String {
        var a = decimal
        let cs = decNumberClassToString(decNumberClass(&a, &HDecimal.context.base))
        return String(cString: cs!)
    }
    
    public var floatingPointClass: FloatingPointClassification {
        var a = self.decimal
        let c = decNumberClass(&a, &HDecimal.context.base)
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
    /// one value (0 to 9) per byte.
    public var bcd : [UInt8] {
        var result = [UInt8](repeating: 0, count: Int(decimal.digits))
        var a = decimal
        decNumberGetBCD(&a, &result)
        return result
    }
    
    /// Returns the bytes comprising the HDecimal number in big endian order.
    public var bytes: [UInt8] { self.bcd }
    
    public var exponent : Int { Int(decimal.exponent) }
    
    public var eps : HDecimal {
        var local = decimal
        var result = decNumber()
        decNumberNextPlus(&result, &local, &HDecimal.context.base)
        var result2 = decNumber()
        decNumberSubtract(&result2, &result, &local, &HDecimal.context.base)
        return HDecimal(result2)
    }
    
    public var isFinite  : Bool  { (decimal.bits & UInt8(DECINF|DECNAN|DECSNAN)) == 0 }
    public var isInfinite: Bool  { (decimal.bits & UInt8(DECINF)) != 0 }
    public var isNaN: Bool       { (decimal.bits & UInt8(DECNAN|DECSNAN)) != 0 }
    public var isNegative: Bool  { (decimal.bits & UInt8(DECNEG)) != 0 }
    public var isZero: Bool      { isFinite && decimal.digits == 1 && decimal.lsu.0 == 0 }
    public var isSubnormal: Bool { var n = decimal; return decNumberIsSubnormal(&n, &HDecimal.context.base) == 1 }
    public var isSpecial: Bool   { (decimal.bits & UInt8(DECINF|DECNAN|DECSNAN)) != 0 }
    public var isCanonical: Bool { true } // "All decNumbers are saintly" - the only joke I found from the original source
    public var isInteger: Bool {
        var local = decimal
        var result = decNumber()
        decContextClearStatus(&HDecimal.context.base, UInt32(DEC_Inexact))
        decNumberToIntegralExact(&result, &local, &HDecimal.context.base)
        if (HDecimal.context.base.status & UInt32(DEC_Inexact)) != 0 {
            decContextClearStatus(&HDecimal.context.base, UInt32(DEC_Inexact)); return false
        }
        return true
    }

    // MARK: - Basic Operations
    
    /// Removes all trailing zeros without changing the value of the number.
    public func normalize () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberNormalize(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public var integer : HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberToIntegralValue(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func remainder (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberRemainder(&result, &a,  &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func negate () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberMinus(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func max (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberMax(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func min (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberMin(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func maxMag (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberMaxMag(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func minMag (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberMinMag(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public var abs : HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberAbs(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func add (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberAdd(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func sub (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberSubtract(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func mul (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberMultiply(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func div (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberDivide(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func idiv (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberDivideInteger(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns *self* + *b* x *c* or multiply accumulate with only the final rounding.
    public func mulAcc (_ b: HDecimal, c: HDecimal) -> HDecimal {
        var b = b
        var c = c
        var a = decimal
        var result = decNumber()
        decNumberFMA(&result, &c.decimal, &b.decimal, &a, &HDecimal.context.base)
        return HDecimal(result)
    }

    /// Rounds to *digits* places where negative values limit the decimal places
    /// and positive values limit the number to multiples of 10 ** digits.
    public func round (_ digits: HDecimal) -> HDecimal {
        var a = decimal
        var b = digits
        var result = decNumber()
        decNumberRescale(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    // MARK: - Scientific Operations
    
    public func pow (_ b: HDecimal) -> HDecimal {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberPower(&result, &a, &b.decimal, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func exp () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberExp(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Natural logarithm
    public func ln () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberLn(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func log10 () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberLog10(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func log2 () -> HDecimal {
        var a = decimal
        var ln2 = HDecimal.ln2.decimal
        var result = decNumber()
        decNumberLn(&result, &a, &HDecimal.context.base)
        decNumberCopy(&a, &result)
        decNumberDivide(&result, &a, &ln2, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    
    public func logB () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberLogB(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns self * 10 ** b
    public func scaleB (_ b: HDecimal) -> HDecimal {
        var a = decimal
        var b = b.decimal
        var result = decNumber()
        decNumberScaleB(&result, &a, &b, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns square root of *self*.
    public func sqrt () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberSquareRoot(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    /// Returns cube root of *self*.
    public func cbrt () -> HDecimal { HDecimal.root(self, 3) }
    
    /// converts decimal numbers to logical
    public func logical () -> HDecimal { abs.convert(fromBase: 10, toBase: 2) }

    /// converts logical numbers to decimal
    public func base10 () -> HDecimal { convert(fromBase: 2, toBase: 10) }
}

extension HDecimal: LogicalOperations {
    
    public var single: decNumber { self.decimal }
    
    // MARK: - Compliance to LogicalOperations
    public func logical() -> decNumber {
//        var s = self.decimal
//        s.exponent = Swift.min(decimal.exponent, 0)  // ignore overflow
        return self.decimal
    }
    public func base10(_ a: decNumber) -> HDecimal { HDecimal(a) }
    
    public var zero: decNumber { decNumber() }
    
    public func decOr(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberOr(a, b, c, &HDecimal.context.base)
    }

    public func decAnd(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberAnd(a, b, c, &HDecimal.context.base)
    }
    
    public func decXor(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberXor(a, b, c, &HDecimal.context.base)
    }
    
    public func decShift(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberShift(a, b, c, &HDecimal.context.base)
    }
    
    public func decRotate(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberRotate(a, b, c, &HDecimal.context.base)
    }
    
    public func decInvert(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!) {
        decNumberInvert(a, b, &HDecimal.context.base)
    }
}

//
// Trigonometric functions
//

extension HDecimal {
    
    static var SINCOS_DIGITS : Int { HDecimal.maximumDigits }
    
    /* Check for right angle multiples and if exact, return the apropriate
     * quadrant constant directly.
     */
    private static func rightAngle(res: inout HDecimal, x: HDecimal, quad: HDecimal, r0: HDecimal, r1: HDecimal, r2: HDecimal, r3: HDecimal) -> Bool {
        var r = x % quad // decNumberRemainder(&r, x, quad, &Ctx);
        if r.isZero { return false }
        if x.isZero {
            res = r0
        } else {
            r = quad + quad // dn_add(&r, quad, quad); dn_compare(&r, &r, x);
            if r == x {
                res = r2
            } else if r.isNegative {
                res = r3
            } else {
                res = r1
            }
        }
        return true
    }
    
    private static func convertToRadians (res: inout HDecimal, x: HDecimal, r0: HDecimal, r1: HDecimal, r2: HDecimal, r3: HDecimal) -> Bool {
        let circle, right : HDecimal
        switch HDecimal.angularMeasure {
            case .radians:  res = x % _2pi; return true // no conversion needed - just reduce the range
            case .degrees:  circle = 360; right = 90
            case .gradians: circle = 400; right = 100
            default: return true
        }
        var fm = x % circle
        if fm.isNegative { fm += circle }
        if rightAngle(res: &res, x: fm, quad: right, r0: r0, r1: r1, r2: r2, r3: r3) { return false }
        res = fm * HDecimal._2pi / circle
        return true
    }
    
    private static func convertFromRadians (res: inout HDecimal, x: HDecimal) {
        let circle: HDecimal
        switch HDecimal.angularMeasure {
            case .radians:  res = x; return    // no conversion needed
            case .degrees:  circle = 360
            case .gradians: circle = 400
            default: return
        }
        res = x * circle / HDecimal._2pi
    }
    
    private static func sincosTaylor(_ a : HDecimal, sout: inout HDecimal?, cout: inout HDecimal?) {
        var a2, t, j, z, s, c : HDecimal
        let digits = HDecimal.digits
        HDecimal.digits = SINCOS_DIGITS
        
        a2 = a.sqr()  // dn_multiply(&a2.n, a, a);
        j = HDecimal.one         // dn_1(&j.n);
        t = HDecimal.one         // dn_1(&t.n);
        s = HDecimal.one         // dn_1(&s.n);
        c = HDecimal.one         // dn_1(&c.n);
        
        var fins = sout == nil
        var finc = cout == nil
        for i in 1..<1000 where !(fins && finc) {
            let odd = (i & 1) != 0
            
            j += HDecimal.one // dn_inc(&j.n);
            z = a2 / j      // dn_divide(&z.n, &a2.n, &j.n);
            t *= z          // dn_multiply(&t.n, &t.n, &z.n);
            if !finc {
                z = c       // decNumberCopy(&z.n, &c.n);
                if odd {
                    c -= t  // dn_subtract(&c.n, &c.n, &t.n);
                } else {
                    c += t  // dn_add(&c.n, &c.n, &t.n);
                }
                if c == z { finc = true }
            }
            
            j += HDecimal.one // dn_inc(&j.n);
            t /= j          // dn_divide(&t.n, &t.n, &j.n);
            if !fins {
                z = s       // decNumberCopy(&z.n, &s.n);
                if odd {
                    s -= t  // dn_subtract(&s.n, &s.n, &t.n);
                } else {
                    s += t  // dn_add(&s.n, &s.n, &t.n);
                }
                if s == z { fins = true }
            }
        }
        
        // round to the required number of digits
        HDecimal.digits = digits
        if sout != nil {
            sout = s * a    // dn_multiply(sout, &s.n, a);
        }
        if cout != nil {
            cout = c + HDecimal.zero    // dn_plus(cout, &c.n);
        }
    }
    
    private static func atan(res: inout HDecimal, x: HDecimal) { res = atan2(y: x, x: one) }
    
    public static func atan2(y: HDecimal, x: HDecimal) -> HDecimal {
        if x.isZero {
            if y.isZero { return HDecimal.nan }
            return y.isNegative ? -pi_2 : pi_2
        } else if y.isZero {
            return x.isNegative ? pi : zero
        }
        if x == y  { return y.isNegative ? -3*pi/4 : pi_2/2 }
        if x == -y { return y.isNegative ? -pi_2/2 : 3*pi/4 }
        
        let r = (x.sqr() + y.sqr()).sqrt()
        let xx = x / r
        let yy = y / r
        
        /* Compute Double precision approximation to atan. */
        var z = HDecimal(Double.atan2(y: y.doubleValue, x: x.doubleValue))
        var sin_z, cos_z: HDecimal!
        sin_z = zero; cos_z = zero
        var zp = zero
        
        if xx.abs > yy.abs {
            /* Use Newton iteration 1.  z' = z + (y - sin(z)) / cos(z)  */
            while z != zp {
                zp = z
                sincosTaylor(z, sout: &sin_z, cout: &cos_z); z += (yy - sin_z) / cos_z
            }
        } else {
            /* Use Newton iteration 2.  z' = z - (x - cos(z)) / sin(z)  */
            while z != zp {
                zp = z
                sincosTaylor(z, sout: &sin_z, cout: &cos_z); z -= (xx - cos_z) / sin_z
            }
        }
        return z
    }
    
    private static func asin(res: inout HDecimal, x: HDecimal) {
        if x.isNaN { res.setNAN(); return }
        
        var abx = x.abs //dn_abs(&abx, x);
        if abx > HDecimal.one { res.setNAN(); return }
        
        // res = 2*atan(x/(1+sqrt(1-x*x)))
        var z = x.sqr()      // dn_multiply(&z, x, x);
        z = HDecimal.one - z  // dn_1m(&z, &z);
        z = z.sqrt()         // dn_sqrt(&z, &z);
        z += HDecimal.one     // dn_inc(&z);
        z = x / z            // dn_divide(&z, x, &z);
        HDecimal.atan(res: &abx, x: z) // do_atan(&abx, &z);
        res = 2 * abx       // dn_mul2(res, &abx);
    }
    
    private static func acos(res: inout HDecimal, x: HDecimal) {
        if x.isNaN { res.setNAN(); return }
        
        var abx = x.abs //dn_abs(&abx, x);
        if abx > HDecimal.one { res.setNAN(); return }
        
        // res = 2*atan((1-x)/sqrt(1-x*x))
        if x == HDecimal.one {
            res = HDecimal.zero
        } else {
            var z = x.sqr()         // dn_multiply(&z, x, x);
            z = HDecimal.one - z     // dn_1m(&z, &z);
            z = z.sqrt()            // dn_sqrt(&z, &z);
            abx = HDecimal.one - x   // dn_1m(&abx, x);
            z = abx / z             // dn_divide(&z, &abx, &z);
            HDecimal.atan(res: &abx, x: z) // do_atan(&abx, &z);
            res = 2 * abx           // dn_mul2(res, &abx);
        }
    }
    
    fileprivate mutating func setNAN() { self.decimal.bits |= UInt8(DECNAN) }    
    fileprivate mutating func setsNAN() { self.decimal.bits |= UInt8(DECSNAN) }
    
    /* Calculate sin and cos of the given number in radians.
     * We need to do some range reduction to guarantee that our Taylor series
     * converges rapidly.
     */
    func sinCos(sinv : inout HDecimal?, cosv : inout HDecimal?) {
        let v = self
        if v.isSpecial { // (decNumberIsSpecial(v)) {
            sinv?.setNAN(); cosv?.setNAN()
        } else {
            let x = v % HDecimal._2pi  // decNumberMod(&x, v, &const_2PI);
            HDecimal.sincosTaylor(x, sout: &sinv, cout: &cosv)  // sincosTaylor(&x, sinv, cosv);
        }
    }
    
    func sin() -> HDecimal {
        let x = self
        var x2 = HDecimal.zero
        var res : HDecimal? = HDecimal.zero
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            if HDecimal.convertToRadians(res: &x2, x: x, r0: 0, r1: 1, r2: 0, r3: 1) {
                HDecimal.sincosTaylor(x2, sout: &res, cout: &HDecimal.Nil)  // sincosTaylor(&x2, res, NULL);
            } else {
                res = x2  // decNumberCopy(res, &x2);
            }
        }
        return res!
    }
    
    func cos() -> HDecimal {
        let x = self
        var x2 = HDecimal.zero
        var res : HDecimal? = HDecimal.zero
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            if HDecimal.convertToRadians(res: &x2, x: x, r0:1, r1:0, r2:1, r3:0) {
                HDecimal.sincosTaylor(x2, sout: &HDecimal.Nil, cout: &res)
            } else {
                res = x2  // decNumberCopy(res, &x2);
            }
        }
        return res!
    }
    
    func tan() -> HDecimal {
        let x = self
        var x2 = HDecimal.zero
        var res : HDecimal? = HDecimal.zero
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            let digits = HDecimal.digits
            HDecimal.digits = HDecimal.SINCOS_DIGITS
            if HDecimal.convertToRadians(res: &x2, x: x, r0:0, r1:HDecimal.NaN, r2:0, r3:HDecimal.NaN) {
                var s, c : HDecimal?
                s = HDecimal.zero; c = HDecimal.zero
                HDecimal.sincosTaylor(x2, sout: &s, cout: &c)
                x2 = s! / c!  // dn_divide(&x2.n, &s.n, &c.n);
            }
            HDecimal.digits = digits
            res = x2 + HDecimal.zero // dn_plus(res, &x2.n);
        }
        return res!
    }
    
    func arcSin() -> HDecimal {
        var res = HDecimal.zero
        HDecimal.asin(res: &res, x: self)
        HDecimal.convertFromRadians(res: &res, x: res)
        return res
    }
    
    func arcCos() -> HDecimal {
        var res = HDecimal.zero
        HDecimal.acos(res: &res, x: self)
        HDecimal.convertFromRadians(res: &res, x: res)
        return res
    }
    
    func arcTan() -> HDecimal {
        let x = self
        var z = HDecimal.zero
        if x.isSpecial {
            if x.isNaN {
                return HDecimal.NaN
            } else {
                z = HDecimal.pi_2
                if x.isNegative { z = -z }
            }
        } else {
            HDecimal.atan(res: &z, x: x)
        }
        HDecimal.convertFromRadians(res: &z, x: z)
        return z
    }
    
    func arcTan2(b: HDecimal) -> HDecimal {
        var z = HDecimal.atan2(y: self, x: b)
        HDecimal.convertFromRadians(res: &z, x: z)
        return z
    }
}

// Mark: - Hyperbolic trig functions
public extension HDecimal {
    
    /* exp(x)-1 */
    static func Expm1(_ x: HDecimal) -> HDecimal {
        if x.isSpecial { return x }
        let u = x.exp()
        return (x+1)*u-1
    }
    
    static func inv(_ d: HDecimal) -> HDecimal { one / d }
    
    func sinh() -> HDecimal {
        let a = self
        if a.isZero { return a }
        
        if a.abs > 0.05 {
            let ea = a.exp()
            return (ea - HDecimal.inv(ea)) * 0.5
        }
        
        /* Since a is small, using the above formula gives
        a lot of cancellation.   So use Taylor series. */
        var s = a
        var t = a
        let r = t.sqr()
        var m = 1
        let thresh = a.ulp
        
        repeat {
            m += 2
            t *= r
            t = t / HDecimal((m-1) * m)
            s += t
        } while t.abs > thresh
        
        return s
    }
    
    fileprivate mutating func setINF()  { self.decimal.bits |= UInt8(DECINF) }
    fileprivate mutating func setNINF() { self.decimal.bits |= UInt8(DECNEG+DECINF) }
    
    func cosh() -> HDecimal {
        let a = self
        if a.isZero { return HDecimal.one }
        
        let ea = a.exp()
        return (ea + HDecimal.inv(ea)) * 0.5
    }
    
    func tanh() -> HDecimal {
        let a = self
        if a.isZero { return a }
        
        if Swift.abs(a.doubleValue) > 0.05 {
            let ea = a.exp()
            let inv_ea = HDecimal.inv(ea)
            return (ea - inv_ea) / (ea + inv_ea)
        } else {
            let s = a.sinh()
            let c = (1.0 + s.sqr()).sqrt()
            return s / c
        }
    }
    
    /* ln(1+x) */
    func Ln1p() -> HDecimal {
        let x = self
        if x.isSpecial || x.isZero {
            return x
        }
        let u = x + HDecimal.one
        var v = u - HDecimal.one
        if v == 0 { return x }
        let w = x / v // dn_divide(&w, x, &v);
        v = u.ln()
        return v * w
    }
    
    func arcSinh() -> HDecimal {
        let x = self
        var y = x.sqr()             // decNumberSquare(&y, x);		// y = x^2
        var z = y + HDecimal.one     // dn_p1(&z, &y);			// z = x^2 + 1
        y = z.sqrt() + HDecimal.one  // dn_sqrt(&y, &z);		// y = sqrt(x^2+1)
        z = x / y + HDecimal.one     // dn_divide(&z, x, &y);
        y = x * z                   // dn_multiply(&y, x, &z);
        return y.Ln1p()
    }
    
    
    func arcCosh() -> HDecimal {
        let x = self
        var res = x.sqr()           // decNumberSquare(res, x);	// r = x^2
        var z = res - HDecimal.one   // dn_m1(&z, res);			// z = x^2 + 1
        res = z.sqrt()               // dn_sqrt(res, &z);		// r = sqrt(x^2+1)
        z = res + x                 // dn_add(&z, res, x);		// z = x + sqrt(x^2+1)
        return z.ln()
    }
    
    func arcTanh() -> HDecimal {
        let x = self
        var res = HDecimal.zero
        if x.isNaN { return HDecimal.NaN }
        var y = x.abs
        if y == HDecimal.one {
            if x.isNegative { res.setNINF(); return res }
            return HDecimal.infinity
        }
        // Not the obvious formula but more stable...
        var z = HDecimal.one - x   // dn_1m(&z, x);
        y = x / z                 // dn_divide(&y, x, &z);
        z = HDecimal.two * y       // dn_mul2(&z, &y);
        y = z.Ln1p()              // decNumberLn1p(&y, &z);
        return y / HDecimal.two
    }
}

// Mark: - Combination/Permutation functions
public extension HDecimal {
    
    static func random (in range: Range<HDecimal> = 0..<1) -> HDecimal {
        let digits = HDecimal.digits  // working digits
        var working = [UInt8](); working.reserveCapacity(digits)
        
        // generate some randome digits
        for _ in 1...digits {
            working.append(UInt8.random(in: 0...9))
        }
        var x = HDecimal(sign: .plus, bcd: working, exponent: -digits+1)
        while x > range.upperBound { x = x.scaleB(-1) }
        if x < range.lowerBound { x += range.lowerBound }
        return x
    }
    
    /* Calculate permutations:
     * C(x, y) = P(x, y) / y! = x! / ( (x-y)! y! )
     */
    func comb (y: HDecimal) -> HDecimal { self.perm(y: y) / y.factorial() }
    
    /* Calculate permutations:
     * P(x, y) = x! / (x-y)!
     */
    func perm (y: HDecimal) -> HDecimal { self.factorial() / (self - y).factorial() }
    
    func gamma () -> HDecimal {
        print("*** WARNING: \(#function) is not released yet and probably doesn't work!")
        let t = self
        let ndp = Double(HDecimal.digits)
        
        let working_prec = ceil(1.5 * ndp)
        HDecimal.digits = Int(working_prec)
        
        print("t = \(t)")
        let a = ceil( 1.25 * ndp / Darwin.log10( 2.0 * Darwin.acos(-1.0) ) )
        
        // Handle improper arguments.
        if t.abs > 1.0e8 {
            print("gamma: argument is too large")
            return HDecimal.infinity
        } else if t.isInteger && t <= 0 {
            print("gamma: invalid negative argument")
            return HDecimal.NaN
        }
        
        // for testing first handle args greater than 1/2
        // expand with branch later.
        var arg : HDecimal
        
        if t < 0.5 {
            arg = 1.0 - t
            
            // divide by zero trap for later compuation of cosecant
            if (HDecimal.pi * t).sin() == 0 {
                print("value of argument is too close to a negative integer or zero.\n" +
                    "sin(pi * t) is zero indicating singularity. Increase precision to fix. ")
                return HDecimal.infinity
            }
        } else {
            arg = t
            
            // quick exit with factorial if integer
            if t.isInteger {
                var temp : HDecimal = HDecimal.one
                for k in 2..<t.int {
                    temp *= HDecimal(k)
                }
                return temp
            }
        }
        
        let N = a - 1
        var sign = -1
        
        let rootTwoPi = HDecimal._2pi.sqrt()
        let oneOverRootTwoPi = HDecimal.one / rootTwoPi
        
        let e = HDecimal.one.exp()
        let oneOverE = HDecimal.one / e
        let x = HDecimal(floatLiteral: a)
        var runningExp = x.exp()
        var runningFactorial = HDecimal.one
        
        var sum = HDecimal.one
        
//        print("x = \(x), runningExp = \(runningExp), runningFactorial = \(runningFactorial)")
        
        // get summation term
        for k in 1...Int(N) {
            sign = -sign
            
            // keep (k-1)! term for computing coefficient
            if k == 1 {
                runningFactorial = HDecimal.one
            } else {
                runningFactorial *= HDecimal(k-1)
            }
            
            runningExp *= oneOverE   // e ^ (a-k). divide by factor of e each iteration
            
            let x1 = HDecimal(floatLiteral: a - Double(k) )
            let x2 = HDecimal(floatLiteral: Double(k) - 0.5)
            
            sum += oneOverRootTwoPi * HDecimal(sign) * runningExp * x1 ** x2 / ( runningFactorial * (arg + HDecimal(k - 1) ))
//            print("Iteration \(k), sum = \(sum)")
        }
        
        // restore the original precision 
        HDecimal.digits = Int(ndp)
        
        // compute using the identity
        let da = HDecimal(floatLiteral: a)
        let arga1 = arg + da - 1
        let arga2 = -arg - da + 1
        if t < 0.5 {
            let temp = rootTwoPi * arga1 ** (arg - 0.5) * arga2.exp() * sum
            return HDecimal.pi / ((HDecimal.pi * t).sin() * temp)
        }
        
        return rootTwoPi * arga1 ** (arg - 0.5) * arga2.exp() * sum
    }
    
    func erf() -> HDecimal {
        print("*** WARNING: \(#function) is not released yet and probably doesn't work!")
        let x = self
        if x.isSpecial || x.isZero { return x }
        
        /* around x=0, we have erf(x) = 2x/sqrt(Pi) (1 - x^2/3 + ...),
           with 1 - x^2/3 <= sqrt(Pi)*erf(x)/2/x <= 1 for x >= 0. This means that
           if x^2/3 < 2^(-PREC(y)-1) we can decide of the correct rounding,
           unless we have a worst-case for 2x/sqrt(Pi). */
        if x.exponent < -HDecimal.digits/2 {
            /* we use 2x/sqrt(Pi) (1 - x^2/3) <= erf(x) <= 2x/sqrt(Pi) for x > 0
               and 2x/sqrt(Pi) <= erf(x) <= 2x/sqrt(Pi) (1 - x^2/3) for x < 0.
               In both cases |2x/sqrt(Pi) (1 - x^2/3)| <= |erf(x)| <= |2x/sqrt(Pi)|.
               We will compute l and h such that l <= |2x/sqrt(Pi) (1 - x^2/3)|
               and |2x/sqrt(Pi)| <= h. If l and h round to the same value to
               precision PREC(y) and rounding rnd_mode, then we are done. */
            var l, h: HDecimal
            let savedDigits = HDecimal.digits
            HDecimal.digits+=17 // increase digits for l, h
            l = HDecimal(0); h = HDecimal(0)
            l = HDecimal.one - (x.sqr() / HDecimal(3))  // lower bound 1 - x^2/3
            h = HDecimal.pi.sqrt()        // upper bound sqrt(pi)
            l = x * HDecimal.two * l / h  // lower bound |2x/sqrt(pi) (1 - x^2/3)|
            
            // now compute h
            h = HDecimal.pi.sqrt() / HDecimal.two // lower bound sqrt(pi)/2
            
            // since sqrt(Pi)/2 < 1, the following should not overflow
            h = x / h
            
            // round to digits
            HDecimal.digits = savedDigits
            l = l + HDecimal.zero
            h = h + HDecimal.zero
            if l == h { return h }
        }
        
        var xf = x / HDecimal.two.ln()   // lower bound |x/log(2)|
        xf = xf * x
        if xf > HDecimal(HDecimal.digits+1) {
            /* |erf x| = 1 or 1-epsilon */
            return HDecimal(signOf: x, magnitudeOf: HDecimal.one)
        } else { // use Taylor
            return x.erf0()
        }
    }
    
    /// evaluates erf(x) using the expansion at x=0:
    ///
    ///   erf(x) = 2/sqrt(Pi) * sum((-1)^k*x^(2k+1)/k!/(2k+1), k=0..infinity)
   ///
   ///    Assumes x is neither NaN nor infinite nor zero.
   ///    Assumes also that e*x^2 <= n (target precision).
    private func erf0 () -> HDecimal {
        let n = HDecimal.digits
        
        // working precision
        let xf2 = self.sqr()
        let m = n + xf2.log2().int + 8 + Int(Double.log2(Double(n)).rounded(.up))
        HDecimal.digits = m
        
        let x = self
        var y = HDecimal(0), s = HDecimal(0), t = HDecimal(0), u = HDecimal(0)
        
        while true {
            y = x.sqr(); s = HDecimal.one; t = HDecimal.one
            var tauk = 0.0
            for k in 1... {
                t = y * t / HDecimal(k)
                u = t / HDecimal(2*k+1)
                var sigmak = s.exponent
                if !sigmak.isMultiple(of: 2) {
                    s = s - u
                } else {
                    s = s + u
                }
                sigmak -= s.exponent
                let nuk = u.exponent - s.exponent
                if nuk < -m && HDecimal(k) >= xf2 { break }
                tauk = 0.5 + mul2exp(tauk, sigmak) + mul2exp(Double(1 + 8 * k), nuk)
            }
            
            s = x * s
            s = HDecimal(sign: .plus, exponent: s.exponent+1, significand: s)
            t = HDecimal.pi.sqrt()
            s = t / s
            tauk = 4 * tauk + 11  /* final ulp-error on s */
//            let log2tauk = Double.log2(tauk)
            
        }
        
    }
    
    private func mul2exp(_ x: Double, _ e: Int) -> Double {
        var x = x
        var e = e
        if e > 0 {
            while e > 0 { x *= 2.0; e-=1 }
        } else {
            while e < 0 { x /= 2.0; e+=1 }
        }
        return x
    }
    
    func factorial() -> HDecimal { Utilities.factorial(self) }
}

// Mark: - SignedNumeric compliance
extension HDecimal : SignedNumeric {
    
    public var magnitude : HDecimal { self.abs }
    public init?<T>(exactly source: T) where T : BinaryInteger { self.init(Int(source)) }
    
    public static func * (lhs: HDecimal, rhs: HDecimal) -> HDecimal { lhs.mul(rhs) }
    public static func *= (lhs: inout HDecimal, rhs: HDecimal) { lhs = lhs.mul(rhs) }
    public static prefix func + (lhs: HDecimal) -> HDecimal { lhs }
    public static func + (lhs: HDecimal, rhs: HDecimal) -> HDecimal { lhs.add(rhs) }

}

// Mark: - CustomStringConvertible compliance
// Support the print() command.
extension HDecimal : CustomStringConvertible {
    
    public var description : String  {
        var cs = [CChar](repeating: 0, count: Int(decimal.digits+14))
        var local = decimal
        decNumberToString(&local, &cs)
        return String(cString: &cs)
    }
    
}

// Mark: - Comparable compliance
extension HDecimal : Comparable {
    
    public func cmp (_ b: HDecimal) -> ComparisonResult {
        var b = b
        var a = decimal
        var result = decNumber()
        decNumberCompare(&result, &a, &b.decimal, &HDecimal.context.base)
        let ai = decNumberToInt32(&result, &HDecimal.context.base)
        switch ai {
        case -1: return .orderedAscending
        case 0:  return .orderedSame
        default: return .orderedDescending
        }
    }
}

// Mark: - ExpressibleByIntegerLiteral compliance
// Allows things like -> a : MGDecimal = 12345
extension HDecimal : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
}

// Mark: - ExpressibleByFloatLiteral compliance
// Note: These conversions are not guaranteed to be exact.
extension HDecimal : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self.init(value) }
}

// Mark: - Hashable compliance
// Allows things like -> a : Set<MGDecimal> = [12.4, 15, 100]
extension HDecimal : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}

// Mark: - ExpressibleByStringLiteral compliance
// Allows things like -> a : MGDecimal = "12345"
extension HDecimal : ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    public init (stringLiteral s: String) { self.init(s)! }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
}

// MARK: - Archival(Codable) Operations
extension HDecimal : Codable {
  
    enum CodingKeys: String, CodingKey {
        case size
        case scale
        case bytes
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let size = try values.decode(Int32.self, forKey: .size)
        var scale = try values.decode(Int32.self, forKey: .scale)
        let bytes = try values.decode([UInt8].self, forKey: .bytes)
        decPackedToNumber(bytes, size, &scale, &decimal)
    }
    
    public func encode(to encoder: Encoder) throws {
        var local = decimal
        var scale = Int32(0)
        let size = Int32(decimal.digits/2+1)
        var bytes = [UInt8](repeating: 0, count: Int(size))
        decPackedFromNumber(&bytes, size, &scale, &local)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(size, forKey: .size)
        try container.encode(scale, forKey: .scale)
        try container.encode(bytes, forKey: .bytes)
    }
}

// Mark: - Power functions
infix operator ** : ExponentPrecedence
infix operator **= : ExponentPrecedence
precedencegroup ExponentPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}

extension HDecimal : Real {
    
    public static func erf(_ x: HDecimal) -> HDecimal {
        HDecimal(Double.erf(x.doubleValue)) // better than nothing
    }
    
    public static func erfc(_ x: HDecimal) -> HDecimal {
        HDecimal(Double.erfc(x.doubleValue)) // better than nothing
    }
    
    public static func exp2(_ x: HDecimal) -> HDecimal { HDecimal.two.pow(x) }
    public static func hypot(_ x: HDecimal, _ y: HDecimal) -> HDecimal { Utilities.hypot(x: x, y: y) }
    public static func gamma(_ x: HDecimal) -> HDecimal { x.gamma() }
    public static func log2(_ x: HDecimal) -> HDecimal { x.log2() }
    public static func log10(_ x: HDecimal) -> HDecimal { x.log10() }
    
    public static func logGamma(_ x: HDecimal) -> HDecimal {
        HDecimal(Double.logGamma(x.doubleValue)) // better than nothing
    }
    
}

extension HDecimal : ElementaryFunctions {
    
    public static func exp(_ x: HDecimal) -> HDecimal { x.exp() }
    public static func expMinusOne(_ x: HDecimal) -> HDecimal { Expm1(x) }
    public static func cosh(_ x: HDecimal) -> HDecimal { x.cosh() }
    public static func sinh(_ x: HDecimal) -> HDecimal { x.sinh() }
    public static func tanh(_ x: HDecimal) -> HDecimal { x.tanh() }
    public static func cos(_ x: HDecimal) -> HDecimal { x.cos() }
    public static func sin(_ x: HDecimal) -> HDecimal { x.sin() }
    public static func tan(_ x: HDecimal) -> HDecimal { x.tan() }
    public static func log(_ x: HDecimal) -> HDecimal { x.ln() }
    public static func log(onePlus x: HDecimal) -> HDecimal { x.Ln1p() }
    public static func acosh(_ x: HDecimal) -> HDecimal { x.arcCosh() }
    public static func asinh(_ x: HDecimal) -> HDecimal { x.arcSinh() }
    public static func atanh(_ x: HDecimal) -> HDecimal { x.arcTanh() }
    public static func acos(_ x: HDecimal) -> HDecimal { x.arcCos() }
    public static func asin(_ x: HDecimal) -> HDecimal { x.arcSin() }
    public static func atan(_ x: HDecimal) -> HDecimal { x.arcTan() }
    public static func pow(_ x: HDecimal, _ y: HDecimal) -> HDecimal { x.pow(y) }
    public static func pow(_ x: HDecimal, _ n: Int) -> HDecimal  { Utilities.power(x, to: n) }
    public static func root(_ x: HDecimal, _ n: Int) -> HDecimal { Utilities.root(value: x, n: n) }
    public static func factorial(_ x: HDecimal) -> HDecimal { Utilities.factorial(x) }
    
}

extension HDecimal : Strideable {
    public func distance(to other: HDecimal) -> HDecimal { self.sub(other) }
    public func advanced(by n: HDecimal) -> HDecimal { self.add(n) }
}

extension HDecimal : FloatingPoint {

    public static func - (_ a: HDecimal, _ b: HDecimal) -> HDecimal { a.sub(b) }
    public var isNormal: Bool { [.negativeNormal, .positiveNormal].contains(floatingPointClass) }

    public static var nan: HDecimal { HDecimal.NaN }
    public static var signalingNaN: HDecimal { HDecimal.sNaN }

    public var ulp: HDecimal { self.eps }
    public var sign: FloatingPointSign { isNegative ? .minus : .plus }
    public var isSignalingNaN: Bool { floatingPointClass == .signalingNaN }

    public mutating func formSquareRoot() { self = self.sqrt() }
    public mutating func addProduct(_ lhs: HDecimal, _ rhs: HDecimal) { self = self.mulAcc(lhs, c: rhs) }

    public func isEqual(to other: HDecimal) -> Bool { self.cmp(other) == .orderedSame }
    public func isLess(than other: HDecimal) -> Bool { self.cmp(other) == .orderedAscending }
    public func isLessThanOrEqualTo(_ other: HDecimal) -> Bool {
        [ComparisonResult.orderedSame, .orderedAscending].contains(self.cmp(other))
    }
  
}



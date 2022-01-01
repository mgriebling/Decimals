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
    
    static var context = DecContext(initKind: .base)
    
    /// Active angular measurement unit
    public static var angularMeasure = UnitAngle.radians
    
    /// Internal number representation
    fileprivate(set) var decimal = decNumber()
    
    private func initContext(digits: Int) {
        HDecimal.context.digits = digits
        HDecimal.context.status = .clearFlags
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
    
    public static var errorString : String { context.status.description }
    
    public static func clearStatus() { context.status = .clearFlags }
    
    public static var roundMethod : rounding {
        get { decContextGetRounding(&context.base) }
        set { decContextSetRounding(&context.base, newValue) }
    }
    
    public static var digits : Int {
        get { context.digits }
        set { context.digits = newValue }
    }
    
    public var nextUp: HDecimal {
        var a = decimal
        var result = decNumber()
        if isNegative {
            decNumberNextMinus(&result, &a, &HDecimal.context.base)
        } else {
            decNumberNextPlus(&result, &a, &HDecimal.context.base)
        }
        return HDecimal(result)
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
    
    public init(_ decimal : HDecimal) { self.decimal = decimal.decimal }
    
    public init<Source>(_ value: Source = 0) where Source : BinaryInteger {
        /* small integers (32-bits) are directly convertible */
        initContext(digits: HDecimal.digits)
        if let rint = Int32(exactly: value) {
            // need this to initialize small Ints
            decNumberFromInt32(&decimal, rint)
        } else {
            let x: HDecimal = Utilities.intToReal(value)
            decimal = x.decimal
        }
    }
    
    public init(_ d: Double) {
        initContext(digits:  HDecimal.digits)
        let n: HDecimal = Utilities.doubleToReal(d)
        self.decimal = n.decimal
    }
    
    public init(sign: FloatingPointSign, exponent: Int, significand: HDecimal) {
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
        var result = decNumber()
        var a = magnitudeOf.decimal
        var sign = signOf.decimal
        decNumberCopySign(&result, &a, &sign)
        decimal = result
    }
    
    public init(_ decimal: Foundation.Decimal) {
        // we cheat since this should be an uncommon thing to do
        let numStr = decimal.description
        self.init(numStr, digits: HDecimal.nominalDigits)!  // Apple Decimals are 38 digits fixed
    }
    
    public init?(_ s: String, radix: Int) { self.init(s, digits: 0, radix: radix) }
    
    public init?(_ s: String, digits: Int = 0, radix: Int = 10) {
        let digits = digits == 0 ? HDecimal.nominalDigits : digits
        initContext(digits: digits)
        if let x = numberFromString(s, digits: digits, radix: radix) {
            decimal = x.decimal; return
        }
        return nil
    }
    
    public func decFromString(_ a: UnsafeMutablePointer<decNumber>!, s: String) {
        decNumberFromString(a, s, &HDecimal.context.base)
    }
    
    public init(sign: FloatingPointSign, bcd: [UInt8], exponent: Int) {
        var bcd = bcd
        initContext(digits: bcd.count)
        decNumberSetBCD(&decimal, &bcd, UInt32(bcd.count))
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
    
    private func getRadixDigitFor(_ n: Int) -> String {
        if n < 10 {
            return String(n)
        } else {
            let offset = n - 10
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            let digit = letters[letters.index(letters.startIndex, offsetBy: offset)]
            return String(digit)
        }
    }
    
    private func getMiniRadixDigits(_ radix: Int) -> String {
        var result = ""
        var radix = radix
        let miniDigits = "₀₁₂₃₄₅₆₇₈₉"
        while radix > 0 {
            let offset = radix % 10; radix /= 10
            let digit = miniDigits[miniDigits.index(miniDigits.startIndex, offsetBy: offset)]
            result = String(digit) + result
        }
        return result
    }
    
    private func convert (fromBase from: Int, toBase base: Int) -> HDecimal {
        let oldDigits = HDecimal.digits
        HDecimal.digits = HDecimal.maximumDigits
        let y = Utilities.convert(num: self, fromBase: from, toBase: base)
        HDecimal.digits = oldDigits
        return y
    }
    
    public func string(withRadix radix : Int, showBase : Bool = false) -> String {
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
        return str
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
    
    private let DECSPECIAL = UInt8(DECINF|DECNAN|DECSNAN)
    public var isFinite  : Bool  { (decimal.bits & DECSPECIAL) == 0 }
    public var isInfinite: Bool  { (decimal.bits & UInt8(DECINF)) != 0 }
    public var isNaN: Bool       { (decimal.bits & UInt8(DECNAN|DECSNAN)) != 0 }
    public var isNegative: Bool  { (decimal.bits & UInt8(DECNEG)) != 0 }
    public var isZero: Bool      { isFinite && decimal.digits == 1 && decimal.lsu.0 == 0 }
    public var isSubnormal: Bool { var n = decimal; return decNumberIsSubnormal(&n, &HDecimal.context.base) == 1 }
    public var isSpecial: Bool   { (decimal.bits & DECSPECIAL) != 0 }
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
    public func round (_ digits: Int) -> HDecimal {
        var a = decimal
        var b = HDecimal(digits)
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
    
    /// Returns self * 10 ** b
    public func scaleB (_ b: HDecimal) -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberLogB(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func sqrt () -> HDecimal {
        var a = decimal
        var result = decNumber()
        decNumberSquareRoot(&result, &a, &HDecimal.context.base)
        return HDecimal(result)
    }
    
    public func cbrt () -> HDecimal { HDecimal.root(self, 3) }
    
    /// converts decimal numbers to logical
    public func logical () -> HDecimal { abs.convert(fromBase: 10, toBase: 2) }

    /// converts logical numbers to decimal
    public func base10 () -> HDecimal { convert(fromBase: 2, toBase: 10) }
}

extension HDecimal: LogicalOperations {
    
    var single: decNumber { self.decimal }
    
    // MARK: - Compliance to LogicalOperations
    func logical() -> decNumber { self.logical().decimal }
    func base10(_ a: decNumber) -> HDecimal { HDecimal(a).base10() }
    
    public var zero: decNumber { decNumber() }
    
    func decOr(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberOr(a, b, c, &HDecimal.context.base)
    }

    func decAnd(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberAnd(a, b, c, &HDecimal.context.base)
    }
    
    func decXor(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberXor(a, b, c, &HDecimal.context.base)
    }
    
    func decShift(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberShift(a, b, c, &HDecimal.context.base)
    }
    
    func decRotate(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!, _ c: UnsafePointer<decNumber>!) {
        decNumberRotate(a, b, c, &HDecimal.context.base)
    }
    
    func decInvert(_ a: UnsafeMutablePointer<decNumber>!, _ b: UnsafePointer<decNumber>!) {
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
    
    private static func atan(res: inout HDecimal, x: HDecimal) {
        var a, b, a2, t, j, z, last : HDecimal
        var doubles = 0
        let neg = x.isNegative
        
        // arrange for a >= 0
        if neg {
            a = -x  // dn_minus(&a, x);
        } else {
            a = x   // decNumberCopy(&a, x);
        }
        
        // reduce range to 0 <= a < 1, using atan(x) = pi/2 - atan(1/x)
        let invert = a > HDecimal.one
        if invert { a = HDecimal.one / a } // dn_divide(&a, &const_1, &a);
        
        // Range reduce to small enough limit to use taylor series
        // using:
        //  tan(x/2) = tan(x)/(1+sqrt(1+tan(x)^2))
        for _ in 0..<1000 {
            if a <= HDecimal("0.1") { break }
            doubles += 1
            // a = a/(1+sqrt(1+a^2)) -- at most 3 iterations.
            b = a.sqr()      // dn_multiply(&b, &a, &a);
            b += HDecimal.one // dn_inc(&b);
            b = b.sqrt()     // dn_sqrt(&b, &b);
            b += HDecimal.one // dn_inc(&b);
            a /= b           // dn_divide(&a, &a, &b);
        }
        
        // Now Taylor series
        // tan(x) = x(1-x^2/3+x^4/5-x^6/7...)
        // We calculate pairs of terms and stop when the estimate doesn't change
        res = 3         // , &const_3);
        j = 5           // decNumberCopy(&j, &const_5);
        a2 = a.sqr()    // dn_multiply(&a2, &a, &a);	// a^2
        t = a2          // decNumberCopy(&t, &a2);
        res = t / res   // dn_divide(res, &t, res);	// s = 1-t/3 -- first two terms
        res = HDecimal.one - res   // dn_1m(res, res);
        
        repeat {	// Loop until there is no digits changed
            last = res
            
            t *= a2     // dn_multiply(&t, &t, &a2);
            z = t / j   // dn_divide(&z, &t, &j);
            res += z    // dn_add(res, res, &z);
            j += HDecimal.two // dn_p2(&j, &j);
            
            t *= a2     // dn_multiply(&t, &t, &a2);
            z = t / j   // dn_divide(&z, &t, &j);
            res += z    // dn_subtract(res, res, &z);
            j += HDecimal.two  // dn_p2(&j, &j);
        } while res != last
        res *= a        // dn_multiply(res, res, &a);
        
        while doubles > 0 {
            res += res      // dn_add(res, res, res);
            doubles -= 1
        }
        
        if invert {
            res = HDecimal.pi_2 - res // dn_subtract(res, &const_PIon2, res);
        }
        
        if neg { res = -res } // dn_minus(res, res);
    }
    
    public static func atan2(y: HDecimal, x: HDecimal) -> HDecimal {
        let xneg = x.isNegative
        let yneg = y.isNegative
        var at = HDecimal.zero
        
        if x.isNaN || y.isNaN { return HDecimal.NaN }
        if y.isZero {
            if yneg {
                if x.isZero {
                    if xneg {
                        at = -HDecimal.pi
                    } else {
                        at = y
                    }
                } else if xneg {
                    at = -HDecimal.pi //decNumberPI(at);
                } else {
                    at = y  // decNumberCopy(at, y);
                }
            } else {
                if x.isZero {
                    if xneg {
                        at = HDecimal.pi // decNumberPI(at);
                    } else {
                        at = HDecimal.zero // decNumberZero(at);
                    }
                } else if xneg {
                    at = HDecimal.pi     // decNumberPI(at);
                } else {
                    at = HDecimal.zero   // decNumberZero(at);
                }
            }
            return at
        }
        if x.isZero  {
            at = HDecimal.pi_2 // decNumberPIon2(at);
            if yneg { at = -at } //  dn_minus(at, at);
            return at
        }
        if x.isInfinite {
            if xneg {
                if y.isInfinite {
                    at = HDecimal.pi * 0.75  // decNumberPI(&t);
                    // dn_multiply(at, &t, &const_0_75);
                    if yneg { at = -at } // dn_minus(at, at);
                } else {
                    at = HDecimal.pi // decNumberPI(at);
                    if yneg { at = -at } // dn_minus(at, at);
                }
            } else {
                if y.isInfinite {
                    at = HDecimal.pi/4    // decNumberPIon2(&t);
                    if yneg { at = -at } // dn_minus(at, at);
                } else {
                    at = HDecimal.zero    // decNumberZero(at);
                    if yneg { at = -at } // dn_minus(at, at);
                }
            }
            return at
        }
        if y.isInfinite  {
            at = HDecimal.pi_2    // decNumberPIon2(at);
            if yneg { at = -at } //  dn_minus(at, at);
            return at
        }
        
        var t = y / x       // dn_divide(&t, y, x);
        var r = HDecimal.zero
        HDecimal.atan(res: &r, x: t) // do_atan(&r, &t);
        if xneg {
            t = HDecimal.pi // decNumberPI(&t);
            if yneg { t = -t } // dn_minus(&t, &t);
        } else {
            t = HDecimal.zero // decNumberZero(&t);
        }
        at = r + t  // dn_add(at, &r, &t);
        if at.isZero && yneg { at = -at } //  dn_minus(at, at);
        return at
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
        var v = u - HDecimal.one
        if v.isZero { return x }
        if v == -1 { return v }
        let w = v * x           // dn_multiply(&w, &v, x);
        v = u.ln()              // dn_ln(&v, &u);
        return w / v
    }
    
    /* Hyperbolic functions.
     * We start with a utility routine that calculates sinh and cosh.
     * We do the sinh as (e^x - 1) (e^x + 1) / (2 e^x) for numerical stability
     * reasons if the value of x is smallish.
     */
    private static func sinhcosh(x: HDecimal, sinhv: inout HDecimal?, coshv: inout HDecimal?) {
        if sinhv != nil {
            if x.abs < 0.5 {
                var u = Expm1(x)
                let t = u / HDecimal.two // dn_div2(&t, &u);
                u += HDecimal.one    // dn_inc(&u);
                let v = t / u       // dn_divide(&v, &t, &u);
                u += HDecimal.one    // dn_inc(&u);
                sinhv = u * v       // dn_multiply(sinhv, &u, &v);
            } else {
                let u = x.exp()     // dn_exp(&u, x);			// u = e^x
                let v = HDecimal.one / u   // decNumberRecip(&v, &u);		// v = e^-x
                let t = u - v       // dn_subtract(&t, &u, &v);	// r = e^x - e^-x
                sinhv = t / HDecimal.two       // dn_div2(sinhv, &t);
            }
        }
        if coshv != nil {
            let u = x.exp()           // dn_exp(&u, x);			// u = e^x
            let v = HDecimal.one / u   // decNumberRecip(&v, &u);		// v = e^-x
            coshv = (u + v) / HDecimal.two       // dn_average(coshv, &v, &u);	// r = (e^x + e^-x)/2
        }
    }
    
    func sinh() -> HDecimal {
        let x = self
        if x.isSpecial {
            if x.isNaN { return HDecimal.NaN }
            return x
        }
        var res : HDecimal? = HDecimal.zero
        HDecimal.sinhcosh(x: x, sinhv: &res, coshv: &HDecimal.Nil)
        return res!
    }
    
    fileprivate mutating func setINF() {
        self.decimal.bits |= UInt8(DECINF)
    }
    
    fileprivate mutating func setNINF() {
        self.decimal.bits |= UInt8(DECNEG+DECINF)
    }
    
    func cosh() -> HDecimal {
        let x = self
        var res : HDecimal? = HDecimal.zero
        if x.isSpecial {
            if x.isNaN { return HDecimal.NaN }
            return HDecimal.infinity
        }
        HDecimal.sinhcosh(x: x, sinhv: &HDecimal.Nil, coshv: &res)
        return res!
    }
    
    func tanh() -> HDecimal {
        let x = self
        if x.isNaN { return HDecimal.NaN }
        if x < 100 {
            if x.isNegative { return -1 }
            return HDecimal.one
        }
        var a = x.sqr()               // dn_add(&a, x, x);
        let b = a.exp()-HDecimal.one   // decNumberExpm1(&b, &a);
        a = b + HDecimal.two           // dn_p2(&a, &b);
        return b / a
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
        res = z.sqr()               // dn_sqrt(res, &z);		// r = sqrt(x^2+1)
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
        var z = x - HDecimal.one   // dn_1m(&z, x);
        y = x / z                 // dn_divide(&y, x, &z);
        z = HDecimal.two * y       // dn_mul2(&z, &y);
        y = z.Ln1p()              // decNumberLn1p(&y, &z);
        return y / HDecimal.two
    }
}

// Mark: - Combination/Permutation functions
public extension HDecimal {
    
    /* Calculate permutations:
     * C(x, y) = P(x, y) / y! = x! / ( (x-y)! y! )
     */
    func comb (y: HDecimal) -> HDecimal {
        return self.perm(y: y) / y.factorial()
    }
    
    /* Calculate permutations:
     * P(x, y) = x! / (x-y)!
     */
    func perm (y: HDecimal) -> HDecimal {
        let xfact = self.factorial()
        return xfact / (self - y).factorial()
    }
    
    func gamma () -> HDecimal {
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
    public init(floatLiteral value: Double) { self.init(String(value))! }  // not exactly representable anyway so we cheat
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
        x
    }
    
    public static func erfc(_ x: HDecimal) -> HDecimal {
        x
    }
    
    public static func exp2(_ x: HDecimal) -> HDecimal { HDecimal.two.pow(x) }
    public static func hypot(_ x: HDecimal, _ y: HDecimal) -> HDecimal { Utilities.hypot(x: x, y: y) }
    public static func gamma(_ x: HDecimal) -> HDecimal { x.gamma() }
    public static func log2(_ x: HDecimal) -> HDecimal { x.log2() }
    public static func log10(_ x: HDecimal) -> HDecimal { x.log10() }
    
    public static func logGamma(_ x: HDecimal) -> HDecimal {
        x
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



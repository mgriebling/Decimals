//
//  Decimal.swift
//  TestDecimals
//
//  Created by Mike Griebling on 4 Sep 2015.
//  Copyright © 2015-2017 Computer Inspirations. All rights reserved.
//
//  Notes: The maximum decimal number size is currently hard-limited to 120 digits
//  via DECNUMDIGITS.  The number of digits per exponent is fixed at six to allow
//  mathematical functions to work.
//

import Foundation
import DecNumbers

public struct Decimal {
    
    public enum Round : UInt32 {
        // A bit kludgey -- I couldn't directly map the decNumber "rounding" enum to Swift.
        case ceiling,       /* round towards +infinity         */
        up,                 /* round away from 0               */
        halfUp,             /* 0.5 rounds up                   */
        halfEven,           /* 0.5 rounds to nearest even      */
        halfDown,           /* 0.5 rounds down                 */
        down,               /* round towards 0 (truncate)      */
        floor,              /* round towards -infinity         */
        r05Up,              /* round for reround               */
        max                 /* enum must be less than this     */
        
        init(_ r: rounding) { self = Round(rawValue: r.rawValue) ?? .halfUp }
        var crounding : rounding { return rounding(self.rawValue) }
    }
    
    public enum AngularMeasure {
        case radians, degrees, gradians
    }
    
    // Class properties
    static let maximumDigits = Int(DECNUMDIGITS)
    static let nominalDigits = 38  // number of decimal digits in Apple's Decimal type
    static var context = decContext()
    static var defaultAngularMeasure = AngularMeasure.radians
    
    // Internal number representation
    fileprivate var decimal = decNumber()
    fileprivate var angularMeasure = Decimal.defaultAngularMeasure
    
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
    
    // MARK: - Internal Constants
    
    public static let pi = Decimal(
        "3.141592653589793238462643383279502884197169399375105820974944592307816406286" +
        "208998628034825342117067982148086513282306647093844609550582231725359408128481" +
        "117450284102701938521105559644622948954930381964428810975665933446128475648233" +
        "786783165271201909145648566923460348610454326648213393607260249141273724587006", digits: maximumDigits)!
    
    public static let π = pi
    public static let zero = Decimal(0)
    public static let one = Decimal(1)
    public static let two = Decimal(2)
    
    fileprivate static var infinity : Decimal { var x = zero; x.setINF(); return x }
    fileprivate static var Nil : Decimal?
    fileprivate static var NaN : Decimal { var x = zero; x.setNAN(); return x }
    fileprivate static let _2pi = two * pi
    fileprivate static let pi_2 = pi / two
    
    public static let radix = 10
    
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
    
    public init(_ decimal : Decimal) { self.decimal = decimal.decimal }
    
    public init(_ uint: UInt) {
        initContext(digits: Decimal.nominalDigits)
        if uint <= UInt(UInt32.max) && uint >= UInt(UInt32.min)  {
            decNumberFromUInt32(&decimal, UInt32(uint))
        } else {
            /* do this the long way */
            let working = uint
            var x = Decimal.zero
            var n = working
            var m = Decimal.one
            while n != 0 {
                let r = n % 10; n /= 10
                if r != 0 { x += m * Decimal(r) }
                m *= 10
            }
            decimal = x.decimal
        }
    }
    
    public init(_ int: Int) {
        /* small integers (32-bits) are directly convertible */
        initContext(digits: Decimal.nominalDigits)
        if int <= Int(Int32.max) && int >= Int(Int32.min)  {
            decNumberFromInt32(&decimal, Int32(int))
        } else if int == Int.min {
            // tricky because Int can't represent -Int.min
            let x = -Decimal(UInt(Int.max)+1)  // Int.max+1 = -Int.min
            decimal = x.decimal
        } else {
            /* do this the long way */
            var x = Decimal(UInt(Swift.abs(int)))
            if int < 0 { x = -x }
            decimal = x.decimal
        }
    }
    
    public init(_ decimal: Foundation.Decimal) {
        // we cheat since this should be an uncommon thing to do
        let numStr = decimal.description
        self.init(numStr, digits: 38)!  // Apple Decimals are 38 digits fixed
    }
    
    private static func digitToInt(_ digit: Character) -> Int? {
        let radixDigits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        if let digitIndex = radixDigits.characters.index(of: digit) {
            return radixDigits.distance(from: radixDigits.startIndex, to:digitIndex)
        }
        return nil   // Error illegal radix character
    }
    
    public init?(_ s: String, digits: Int = Decimal.nominalDigits, radix: Int = 10) {
        initContext(digits: digits)
        var ls = s.replacingOccurrences(of: "_", with: "").uppercased()  // remove underscores
        if radix == 10 {
            // use library function for string conversion
            decNumberFromString(&decimal, ls, &Decimal.context)
        } else {
            // convert non-base 10 string to a Decimal number
            var number = Decimal.zero
            let radixNumber = Decimal(radix)
            for digit in ls.characters {
                if let digitNumber = Decimal.digitToInt(digit) {
                    number = number * radixNumber + Decimal(digitNumber)
                } else {
                    return nil
                }
            }
            decimal = number.decimal
        }
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
            let digit = letters[letters.characters.index(letters.startIndex, offsetBy: offset)]
            return String(digit)
        }
    }
    
    private func getMiniRadixDigits(_ radix: Int) -> String {
        var result = ""
        var radix = radix
        let miniDigits = "₀₁₂₃₄₅₆₇₈₉"
        while radix > 0 {
            let offset = radix % 10; radix /= 10
            let digit = miniDigits[miniDigits.characters.index(miniDigits.startIndex, offsetBy: offset)]
            result = String(digit) + result
        }
        return result
    }
    
    private func convert (fromBase from: Int, toBase base: Int) -> Decimal {
        let oldDigits = Decimal.digits
        Decimal.digits = Decimal.maximumDigits
        let to = Decimal(base)
        let from = Decimal(from)
        var y = Decimal.zero
        var n = self
        var scale = Decimal.one
        while !n.isZero {
            let digit = n % to
            y += scale * digit
            n = n.idiv(to)
            scale *= from
        }
        Decimal.digits = oldDigits
        return y
    }
    
    public func string(withRadix radix : Int, showBase : Bool = false) -> String {
        var n = self.integer.abs
        
        // restrict to legal radix values 2 to 36
        let dradix = Decimal(Swift.min(36, Swift.max(radix, 2)))
        var str = ""
        while !n.isZero {
            let digit = n % dradix
            n = n.idiv(dradix)
            str = getRadixDigitFor(digit.int) + str
        }
        if showBase { str += getMiniRadixDigits(radix) }
        return str
    }
    
    public static var decNumberVersionString : String {
        return String(cString: decNumberVersion())
    }
    
    public var int : Int {
        var local = decimal
        if self <= Decimal(Int(Int32.max)) && self >= Decimal(Int(Int32.min)) {
            return Int(decNumberToInt32(&local, &Decimal.context))
        } else if self < Decimal(Int.min) {
            return Int.min
        } else if self > Decimal(Int.max) {
            return Int.max
        } else {
            return Int(description) ?? 0
        }
    }
    
    public var uint : UInt {
        var local = decimal
        if self <= Decimal(UInt(UInt32.max)) {
            return UInt(decNumberToUInt32(&local, &Decimal.context))
        } else if self > Decimal(UInt.max) {
            return UInt.max
        } else {
            return UInt(description) ?? 0
        }
    }
    
    /// Returns the type of number (e.g., "NaN", "+Normal", etc.)
    public var numberClass : String {
        var a = decimal
        let cs = decNumberClassToString(decNumberClass(&a, &Decimal.context))
        return String(cString: cs!)
    }
    
    public var floatingPointClass: FloatingPointClassification {
        var a = self.decimal
        let c = decNumberClass(&a, &Decimal.context)
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
    
    public var exponent : Int { return Int(decimal.exponent) }
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
    public var isSpecial: Bool   { return decimal.bits & DECSPECIAL != 0 }
    public var isInteger: Bool {
        var local = decimal
        decNumberToIntegralExact(&local, &local, &Decimal.context)
        if Decimal.context.status & UInt32(DEC_Inexact) != 0 {
            decContextClearStatus(&Decimal.context, UInt32(DEC_Inexact)); return false
        }
        return true
    }

    // MARK: - Basic Operations
    
    /// Removes all trailing zeros without changing the value of the number.
    public func normalize () -> Decimal {
        var a = decimal
        decNumberNormalize(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public var integer : Decimal {
        var a = decimal
        decNumberToIntegralValue(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func remainder (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberRemainder(&a, &a,  &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func negate () -> Decimal {
        var a = decimal
        decNumberMinus(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func max (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberMax(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func min (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberMin(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public var abs : Decimal {
        var a = decimal
        decNumberAbs(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func add (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberAdd(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func sub (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberSubtract(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func mul (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberMultiply(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func div (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberDivide(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func idiv (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberDivideInteger(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    /// Returns *self* × *b* + *c* or multiply accumulate with only the final rounding.
    public func mulAcc (_ b: Decimal, c: Decimal) -> Decimal {
        var b = b
        var c = c
        var a = decimal
        decNumberFMA(&a, &a, &b.decimal, &c.decimal, &Decimal.context)
        return Decimal(a)
    }

    /// Rounds to *digits* places where negative values limit the decimal places
    /// and positive values limit the number to multiples of 10 ** digits.
    public func round (_ digits: Int) -> Decimal {
        var a = decimal
        var b = Decimal(digits)
        decNumberRescale(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    // MARK: - Scientific Operations
    
    public func pow (_ b: Decimal) -> Decimal {
        var b = b
        var a = decimal
        decNumberPower(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func exp () -> Decimal {
        var a = decimal
        decNumberExp(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Natural logarithm
    public func ln () -> Decimal {
        var a = decimal
        decNumberLn(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func log10 () -> Decimal {
        var a = decimal
        decNumberLog10(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Returns self * 10 ** b
    public func scaleB (_ b: Decimal) -> Decimal {
        var a = decimal
        decNumberLogB(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    public func sqrt () -> Decimal {
        var a = decimal
        decNumberSquareRoot(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    
    // MARK: - Logical Operations
    
    public func or (_ b: Decimal) -> Decimal {
        var b = b.logical()
        var a = logical().decimal
        decNumberOr(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func and (_ b: Decimal) -> Decimal {
        var b = b.logical()
        var a = logical().decimal
        decNumberAnd(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func xor (_ b: Decimal) -> Decimal {
        var b = b.logical()
        var a = logical().decimal
        decNumberXor(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func not () -> Decimal {
        var a = logical().decimal
        decNumberInvert(&a, &a, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func shift (_ bits: Decimal) -> Decimal {
        var bits = bits
        var a = logical().decimal
        decNumberShift(&a, &a, &bits.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func rotate (_ bits: Decimal) -> Decimal {
        var bits = bits
        var a = logical().decimal
        decNumberRotate(&a, &a, &bits.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func logical () -> Decimal {
        // converts decimal numbers to logical
        return integer.abs.convert(fromBase: 10, toBase: 2)
    }
    
    public func base10 () -> Decimal {
        // converts logical numbers to decimal
        return convert(fromBase: 2, toBase: 10)
    }
}

//
// Trigonometric functions
//

extension Decimal {
    
    public static var SINCOS_DIGITS : Int { return Decimal.maximumDigits }
    
    /* Check for right angle multiples and if exact, return the apropriate
     * quadrant constant directly.
     */
    private static func rightAngle(res: inout Decimal, x: Decimal, quad: Decimal, r0: Decimal, r1: Decimal, r2: Decimal, r3: Decimal) -> Bool {
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
    
    private static func convertToRadians (res: inout Decimal, x: Decimal, r0: Decimal, r1: Decimal, r2: Decimal, r3: Decimal) -> Bool {
        let circle, right : Decimal
        switch x.angularMeasure {
        case .radians:  res = x % _2pi; return true // no conversion needed - just reduce the range
        case .degrees:  circle = 360; right = 90
        case .gradians: circle = 400; right = 100
        }
        var fm = x % circle
        if fm.isNegative { fm += circle }
        if rightAngle(res: &res, x: fm, quad: right, r0: r0, r1: r1, r2: r2, r3: r3) { return false }
        res = fm * Decimal._2pi / circle
        return true
    }
    
    private static func convertFromRadians (res: inout Decimal, x: Decimal) {
        let circle: Decimal
        switch x.angularMeasure {
        case .radians:  res = x; return    // no conversion needed
        case .degrees:  circle = 360
        case .gradians: circle = 400
        }
        res = x * circle / Decimal._2pi
    }
    
    private static func sincosTaylor(_ a : Decimal, sout: inout Decimal?, cout: inout Decimal?) {
        var a2, t, j, z, s, c : Decimal
        let digits = Decimal.digits
        Decimal.digits = SINCOS_DIGITS
        
        a2 = a.sqr()  // dn_multiply(&a2.n, a, a);
        j = Decimal.one         // dn_1(&j.n);
        t = Decimal.one         // dn_1(&t.n);
        s = Decimal.one         // dn_1(&s.n);
        c = Decimal.one         // dn_1(&c.n);
        
        var fins = sout == nil
        var finc = cout == nil
        for i in 1..<1000 where !(fins && finc) {
            let odd = (i & 1) != 0
            
            j += Decimal.one // dn_inc(&j.n);
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
            
            j += Decimal.one // dn_inc(&j.n);
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
        Decimal.digits = digits
        if sout != nil {
            sout = s * a    // dn_multiply(sout, &s.n, a);
        }
        if cout != nil {
            cout = c + Decimal.zero    // dn_plus(cout, &c.n);
        }
    }
    
    private static func atan(res: inout Decimal, x: Decimal) {
        var a, b, a2, t, j, z, last : Decimal
        var doubles = 0
        let neg = x.isNegative
        
        // arrange for a >= 0
        if neg {
            a = -x  // dn_minus(&a, x);
        } else {
            a = x   // decNumberCopy(&a, x);
        }
        
        // reduce range to 0 <= a < 1, using atan(x) = pi/2 - atan(1/x)
        let invert = a > Decimal.one
        if invert { a = Decimal.one / a } // dn_divide(&a, &const_1, &a);
        
        // Range reduce to small enough limit to use taylor series
        // using:
        //  tan(x/2) = tan(x)/(1+sqrt(1+tan(x)^2))
        for _ in 0..<1000 {
            if a <= Decimal("0.1") { break }
            doubles += 1
            // a = a/(1+sqrt(1+a^2)) -- at most 3 iterations.
            b = a.sqr()      // dn_multiply(&b, &a, &a);
            b += Decimal.one // dn_inc(&b);
            b = b.sqrt()     // dn_sqrt(&b, &b);
            b += Decimal.one // dn_inc(&b);
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
        res = Decimal.one - res   // dn_1m(res, res);
        
        repeat {	// Loop until there is no digits changed
            last = res
            
            t *= a2     // dn_multiply(&t, &t, &a2);
            z = t / j   // dn_divide(&z, &t, &j);
            res += z    // dn_add(res, res, &z);
            j += Decimal.two // dn_p2(&j, &j);
            
            t *= a2     // dn_multiply(&t, &t, &a2);
            z = t / j   // dn_divide(&z, &t, &j);
            res += z    // dn_subtract(res, res, &z);
            j += Decimal.two  // dn_p2(&j, &j);
        } while res != last
        res *= a        // dn_multiply(res, res, &a);
        
        while doubles > 0 {
            res += res      // dn_add(res, res, res);
            doubles -= 1
        }
        
        if invert {
            res = Decimal.pi_2 - res // dn_subtract(res, &const_PIon2, res);
        }
        
        if neg { res = -res } // dn_minus(res, res);
    }
    
    private static func atan2(y: Decimal, x: Decimal) -> Decimal {
        let xneg = x.isNegative
        let yneg = y.isNegative
        var at = Decimal.zero
        
        if x.isNaN || y.isNaN { return Decimal.NaN }
        if y.isZero {
            if yneg {
                if x.isZero {
                    if xneg {
                        at = -Decimal.pi
                    } else {
                        at = y
                    }
                } else if xneg {
                    at = -Decimal.pi //decNumberPI(at);
                } else {
                    at = y  // decNumberCopy(at, y);
                }
            } else {
                if x.isZero {
                    if xneg {
                        at = Decimal.pi // decNumberPI(at);
                    } else {
                        at = Decimal.zero // decNumberZero(at);
                    }
                } else if xneg {
                    at = Decimal.pi     // decNumberPI(at);
                } else {
                    at = Decimal.zero   // decNumberZero(at);
                }
            }
            return at
        }
        if x.isZero  {
            at = Decimal.pi_2 // decNumberPIon2(at);
            if yneg { at = -at } //  dn_minus(at, at);
            return at
        }
        if x.isInfinite {
            if xneg {
                if y.isInfinite {
                    at = Decimal.pi * 0.75  // decNumberPI(&t);
                    // dn_multiply(at, &t, &const_0_75);
                    if yneg { at = -at } // dn_minus(at, at);
                } else {
                    at = Decimal.pi // decNumberPI(at);
                    if yneg { at = -at } // dn_minus(at, at);
                }
            } else {
                if y.isInfinite {
                    at = Decimal.pi/4    // decNumberPIon2(&t);
                    if yneg { at = -at } // dn_minus(at, at);
                } else {
                    at = Decimal.zero    // decNumberZero(at);
                    if yneg { at = -at } // dn_minus(at, at);
                }
            }
            return at
        }
        if y.isInfinite  {
            at = Decimal.pi_2    // decNumberPIon2(at);
            if yneg { at = -at } //  dn_minus(at, at);
            return at
        }
        
        var t = y / x       // dn_divide(&t, y, x);
        var r = Decimal.zero
        Decimal.atan(res: &r, x: t) // do_atan(&r, &t);
        if xneg {
            t = Decimal.pi // decNumberPI(&t);
            if yneg { t = -t } // dn_minus(&t, &t);
        } else {
            t = Decimal.zero // decNumberZero(&t);
        }
        at = r + t  // dn_add(at, &r, &t);
        if at.isZero && yneg { at = -at } //  dn_minus(at, at);
        return at
    }
    
    private static func asin(res: inout Decimal, x: Decimal) {
        if x.isNaN { res.setNAN(); return }
        
        var abx = x.abs //dn_abs(&abx, x);
        if abx > Decimal.one { res.setNAN(); return }
        
        // res = 2*atan(x/(1+sqrt(1-x*x)))
        var z = x.sqr()      // dn_multiply(&z, x, x);
        z = Decimal.one - z  // dn_1m(&z, &z);
        z = z.sqrt()         // dn_sqrt(&z, &z);
        z += Decimal.one     // dn_inc(&z);
        z = x / z            // dn_divide(&z, x, &z);
        Decimal.atan(res: &abx, x: z) // do_atan(&abx, &z);
        res = 2 * abx       // dn_mul2(res, &abx);
    }
    
    private static func acos(res: inout Decimal, x: Decimal) {
        if x.isNaN { res.setNAN(); return }
        
        var abx = x.abs //dn_abs(&abx, x);
        if abx > Decimal.one { res.setNAN(); return }
        
        // res = 2*atan((1-x)/sqrt(1-x*x))
        if x == Decimal.one {
            res = Decimal.zero
        } else {
            var z = x.sqr()         // dn_multiply(&z, x, x);
            z = Decimal.one - z     // dn_1m(&z, &z);
            z = z.sqrt()            // dn_sqrt(&z, &z);
            abx = Decimal.one - x   // dn_1m(&abx, x);
            z = abx / z             // dn_divide(&z, &abx, &z);
            Decimal.atan(res: &abx, x: z) // do_atan(&abx, &z);
            res = 2 * abx           // dn_mul2(res, &abx);
        }
    }
    
    fileprivate mutating func setNAN() {
        self.decimal.bits |= UInt8(DECNAN)
    }
    
    /* Calculate sin and cos of the given number in radians.
     * We need to do some range reduction to guarantee that our Taylor series
     * converges rapidly.
     */
    public func sinCos(sinv : inout Decimal?, cosv : inout Decimal?) {
        let v = self
        if v.isSpecial { // (decNumberIsSpecial(v)) {
            sinv?.setNAN(); cosv?.setNAN()
        } else {
            let x = v % Decimal._2pi  // decNumberMod(&x, v, &const_2PI);
            Decimal.sincosTaylor(x, sout: &sinv, cout: &cosv)  // sincosTaylor(&x, sinv, cosv);
        }
    }
    
    public func sin() -> Decimal {
        let x = self
        var x2 = Decimal.zero
        var res : Decimal? = Decimal.zero
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            if Decimal.convertToRadians(res: &x2, x: x, r0: 0, r1: 1, r2: 0, r3: 1) {
                Decimal.sincosTaylor(x2, sout: &res, cout: &Decimal.Nil)  // sincosTaylor(&x2, res, NULL);
            } else {
                res = x2  // decNumberCopy(res, &x2);
            }
        }
        return res!
    }
    
    public func cos() -> Decimal {
        let x = self
        var x2 = Decimal.zero
        var res : Decimal? = Decimal.zero
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            if Decimal.convertToRadians(res: &x2, x: x, r0:1, r1:0, r2:1, r3:0) {
                Decimal.sincosTaylor(x2, sout: &Decimal.Nil, cout: &res)
            } else {
                res = x2  // decNumberCopy(res, &x2);
            }
        }
        return res!
    }
    
    public func tan() -> Decimal {
        let x = self
        var x2 = Decimal.zero
        var res : Decimal? = Decimal.zero
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            let digits = Decimal.digits
            Decimal.digits = Decimal.SINCOS_DIGITS
            if Decimal.convertToRadians(res: &x2, x: x, r0:0, r1:Decimal.NaN, r2:0, r3:Decimal.NaN) {
                var s, c : Decimal?
                Decimal.sincosTaylor(x2, sout: &s, cout: &c)
                x2 = s! / c!  // dn_divide(&x2.n, &s.n, &c.n);
            }
            Decimal.digits = digits
            res = x2 + Decimal.zero // dn_plus(res, &x2.n);
        }
        return res!
    }
    
    public func arcSin() -> Decimal {
        var res = Decimal.zero
        Decimal.asin(res: &res, x: self)
        Decimal.convertFromRadians(res: &res, x: res)
        return res
    }
    
    public func arcCos() -> Decimal {
        var res = Decimal.zero
        Decimal.acos(res: &res, x: self)
        Decimal.convertFromRadians(res: &res, x: res)
        return res
    }
    
    public func arcTan() -> Decimal {
        let x = self
        var z = Decimal.zero
        if x.isSpecial {
            if x.isNaN {
                return Decimal.NaN
            } else {
                z = Decimal.pi_2
                if x.isNegative { z = -z }
            }
        } else {
            Decimal.atan(res: &z, x: x)
        }
        Decimal.convertFromRadians(res: &z, x: z)
        return z
    }
    
    public func arcTan2(b: Decimal) -> Decimal {
        var z = Decimal.atan2(y: self, x: b)
        Decimal.convertFromRadians(res: &z, x: z)
        return z
    }
}

//
// Hyperbolic trig functions
//

extension Decimal {
    
    /* exp(x)-1 */
    private static func Expm1(_ x: Decimal) -> Decimal {
        if x.isSpecial { return x }
        let u = x.exp()
        var v = u - Decimal.one
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
    private static func sinhcosh(x: Decimal, sinhv: inout Decimal?, coshv: inout Decimal?) {
        if sinhv != nil {
            if x.abs < 0.5 {
                var u = Expm1(x)
                let t = u / Decimal.two // dn_div2(&t, &u);
                u += Decimal.one    // dn_inc(&u);
                let v = t / u       // dn_divide(&v, &t, &u);
                u += Decimal.one    // dn_inc(&u);
                sinhv = u * v       // dn_multiply(sinhv, &u, &v);
            } else {
                let u = x.exp()     // dn_exp(&u, x);			// u = e^x
                let v = Decimal.one / u   // decNumberRecip(&v, &u);		// v = e^-x
                let t = u - v       // dn_subtract(&t, &u, &v);	// r = e^x - e^-x
                sinhv = t / Decimal.two       // dn_div2(sinhv, &t);
            }
        }
        if coshv != nil {
            let u = x.exp()           // dn_exp(&u, x);			// u = e^x
            let v = Decimal.one / u   // decNumberRecip(&v, &u);		// v = e^-x
            coshv = (u + v) / Decimal.two       // dn_average(coshv, &v, &u);	// r = (e^x + e^-x)/2
        }
    }
    
    public func sinh() -> Decimal {
        let x = self
        if x.isSpecial {
            if x.isNaN { return Decimal.NaN }
            return x
        }
        var res : Decimal? = Decimal.zero
        Decimal.sinhcosh(x: x, sinhv: &res, coshv: &Decimal.Nil)
        return res!
    }
    
    fileprivate mutating func setINF() {
        self.decimal.bits |= UInt8(DECINF)
    }
    
    fileprivate mutating func setNINF() {
        self.decimal.bits |= UInt8(DECNEG+DECINF)
    }
    
    public func cosh() -> Decimal {
        let x = self
        var res : Decimal? = Decimal.zero
        if x.isSpecial {
            if x.isNaN { return Decimal.NaN }
            return Decimal.infinity
        }
        Decimal.sinhcosh(x: x, sinhv: &Decimal.Nil, coshv: &res)
        return res!
    }
    
    public func tanh() -> Decimal {
        let x = self
        if x.isNaN { return Decimal.NaN }
        if x < 100 {
            if x.isNegative { return -1 }
            return Decimal.one
        }
        var a = x.sqr()               // dn_add(&a, x, x);
        let b = a.exp()-Decimal.one   // decNumberExpm1(&b, &a);
        a = b + Decimal.two           // dn_p2(&a, &b);
        return b / a
    }
    
    /* ln(1+x) */
    private func Ln1p() -> Decimal {
        let x = self
        if x.isSpecial || x.isZero {
            return x
        }
        let u = x + Decimal.one
        var v = u - Decimal.one
        if v == 0 { return x }
        let w = x / v // dn_divide(&w, x, &v);
        v = u.ln()
        return v * w
    }
    
    public func arcSinh() -> Decimal {
        let x = self
        var y = x.sqr()             // decNumberSquare(&y, x);		// y = x^2
        var z = y + Decimal.one     // dn_p1(&z, &y);			// z = x^2 + 1
        y = z.sqrt() + Decimal.one  // dn_sqrt(&y, &z);		// y = sqrt(x^2+1)
        z = x / y + Decimal.one     // dn_divide(&z, x, &y);
        y = x * z                   // dn_multiply(&y, x, &z);
        return y.Ln1p()
    }
    
    
    public func arcCosh() -> Decimal {
        let x = self
        var res = x.sqr()           // decNumberSquare(res, x);	// r = x^2
        var z = res - Decimal.one   // dn_m1(&z, res);			// z = x^2 + 1
        res = z.sqr()               // dn_sqrt(res, &z);		// r = sqrt(x^2+1)
        z = res + x                 // dn_add(&z, res, x);		// z = x + sqrt(x^2+1)
        return z.ln()
    }
    
    public func arcTanh() -> Decimal {
        let x = self
        var res = Decimal.zero
        if x.isNaN { return Decimal.NaN }
        var y = x.abs
        if y == Decimal.one {
            if x.isNegative { res.setNINF(); return res }
            return Decimal.infinity
        }
        // Not the obvious formula but more stable...
        var z = x - Decimal.one   // dn_1m(&z, x);
        y = x / z                 // dn_divide(&y, x, &z);
        z = Decimal.two * y       // dn_mul2(&z, &y);
        y = z.Ln1p()              // decNumberLn1p(&y, &z);
        return y / Decimal.two
    }

}

//
// Combination/Permutation functions
//

extension Decimal {
    
    /* Calculate permutations:
     * C(x, y) = P(x, y) / y! = x! / ( (x-y)! y! )
     */
    public func comb (y: Decimal) -> Decimal {
        return self.perm(y: y) / y.factorial()
    }
    
    /* Calculate permutations:
     * P(x, y) = x! / (x-y)!
     */
    public func perm (y: Decimal) -> Decimal {
        let xfact = self.factorial()
        return xfact / (self - y).factorial()
    }
    
    public func gamma () -> Decimal {
        let t = self
        let ndp = Double(Decimal.digits)
        
        let working_prec = ceil(1.5 * ndp)
        Decimal.digits = Int(working_prec)
        
        print("t = \(t)")
        let a = ceil( 1.25 * ndp / Darwin.log10( 2.0 * acos(-1.0) ) )
        
        // Handle improper arguments.
        if t.abs > 1.0e8 {
            print("gamma: argument is too large")
            return Decimal.infinity
        } else if t.isInteger && t <= 0 {
            print("gamma: invalid negative argument")
            return Decimal.NaN
        }
        
        // for testing first handle args greater than 1/2
        // expand with branch later.
        var arg : Decimal
        
        if t < 0.5 {
            arg = 1.0 - t
            
            // divide by zero trap for later compuation of cosecant
            if (Decimal.pi * t).sin() == 0 {
                print("value of argument is too close to a negative integer or zero.\n" +
                    "sin(pi * t) is zero indicating singularity. Increase precision to fix. ")
                return Decimal.infinity
            }
        } else {
            arg = t
            
            // quick exit with factorial if integer
            if t.isInteger {
                var temp = Decimal.one
                for k in 2..<t.int {
                    temp *= Decimal(k)
                }
                return temp
            }
        }
        
        let N = a - 1
        var sign = -1
        
        let rootTwoPi = Decimal._2pi.sqrt()
        let oneOverRootTwoPi = Decimal.one / rootTwoPi
        
        let e = Decimal.one.exp()
        let oneOverE = Decimal.one / e
        let x = Decimal(floatLiteral: a)
        var runningExp = x.exp()
        var runningFactorial = Decimal.one
        
        var sum = Decimal.one
        
//        print("x = \(x), runningExp = \(runningExp), runningFactorial = \(runningFactorial)")
        
        // get summation term
        for k in 1...Int(N) {
            sign = -sign
            
            // keep (k-1)! term for computing coefficient
            if k == 1 {
                runningFactorial = Decimal.one
            } else {
                runningFactorial *= Decimal(k-1)
            }
            
            runningExp *= oneOverE   // e ^ (a-k). divide by factor of e each iteration
            
            let x1 = Decimal(floatLiteral: a - Double(k) )
            let x2 = Decimal(floatLiteral: Double(k) - 0.5)
            
            sum += oneOverRootTwoPi * Decimal(sign) * runningExp * x1 ** x2 / ( runningFactorial * (arg + Decimal(k - 1) ))
//            print("Iteration \(k), sum = \(sum)")
        }
        
        // restore the original precision 
        Decimal.digits = Int(ndp)
        
        // compute using the identity
        let da = Decimal(floatLiteral: a)
        let arga1 = arg + da - 1
        let arga2 = -arg - da + 1
        if t < 0.5 {
            let temp = rootTwoPi * arga1 ** (arg - 0.5) * arga2.exp() * sum
            return Decimal.pi / ((Decimal.pi * t).sin() * temp)
        }
        
        return rootTwoPi * arga1 ** (arg - 0.5) * arga2.exp() * sum
    }
    
    public func factorial () -> Decimal {
        let x = self + Decimal.one
        return x.gamma()
    }
    
}

//
// Add global support for abs().
//

extension Decimal : AbsoluteValuable {
    
    public static func abs (_ a: Decimal) -> Decimal {
        return a.abs
    }
    
}

//
// Support the SignedNumber protocol.
//

extension Decimal : SignedNumber {
    
    static public func - (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.sub(rhs) }
    static public prefix func - (a: Decimal) -> Decimal { return a.negate() }
    
}

//
// Support the print() command.
//

extension Decimal : CustomStringConvertible {
    
    public var description : String  {
        var cs = [CChar](repeating: 0, count: Int(decimal.digits+14))
        var local = decimal
        decNumberToString(&local, &cs)
        return String(cString: &cs)
    }
    
}

//
// Comparison and equality operator definitions
//

extension Decimal : Comparable {
    
    public func cmp (_ b: Decimal) -> ComparisonResult {
        var b = b
        var a = decimal
        decNumberCompare(&a, &a, &b.decimal, &Decimal.context)
        let ai = decNumberToInt32(&a, &Decimal.context)
        switch ai {
        case -1: return .orderedAscending
        case 0:  return .orderedSame
        default: return .orderedDescending
        }
    }
    
    static public func == (lhs: Decimal, rhs: Decimal) -> Bool {
        return lhs.cmp(rhs) == .orderedSame
    }
    
    static public func < (lhs: Decimal, rhs: Decimal) -> Bool {
        return lhs.cmp(rhs) == .orderedAscending
    }
    
}

//
// Allows things like -> a : Decimal = 12345
//

extension Decimal : ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) { self.init(value) }
    
}

//
// Allows things like -> a : [Decimal] = [1.2, 3.4, 5.67]
// Note: These conversions are not guaranteed to be exact.
//

extension Decimal : ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: Double) { self.init(String(value))! }  // not exactly representable anyway so we cheat
    
}

//
// Allows things like -> a : Set<Decimal> = [12.4, 15, 100]
//

extension Decimal : Hashable {
    
    public var hashValue : Int {
        return description.hashValue   // probably not very fast but not used much anyway
    }
    
}

//
// Allows things like -> a : Decimal = "12345"
//

extension Decimal : ExpressibleByStringLiteral {
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    public init (stringLiteral s: String) { self.init(s)! }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
    
}

//
// Convenience functions
//

extension Decimal {
    
    public func sqr() -> Decimal { return self * self }
    public var ² : Decimal { return sqr() }
    
}

extension Decimal : Strideable {
    
    public typealias Stride = Decimal
    
    public func advanced(by stride: Stride) -> Decimal {
        return self+stride
    }
    
    public func distance(to x: Decimal) -> Stride {
        return Decimal.abs(self-x)
    }
    
}

extension Decimal {
    
    // MARK: - Archival Operations
    
    static var UInt8Type = "C".cString(using: String.Encoding.ascii)!
    static var Int32Type = "l".cString(using: String.Encoding.ascii)!
    
    public init? (coder: NSCoder) {
        var scale : Int32 = 0
        var size : Int32 = 0
        coder.decodeValue(ofObjCType: &Decimal.Int32Type, at: &size)
        coder.decodeValue(ofObjCType: &Decimal.Int32Type, at: &scale)
        var bytes = [UInt8](repeating: 0, count: Int(size))
        coder.decodeArray(ofObjCType: &Decimal.UInt8Type, count: Int(size), at: &bytes)
        decPackedToNumber(&bytes, Int32(size), &scale, &decimal)
    }
    
    public func encode(with coder: NSCoder) {
        var local = decimal
        var scale : Int32 = 0
        var size = decimal.digits/2+1
        var bytes = [UInt8](repeating: 0, count: Int(size))
        decPackedFromNumber(&bytes, size, &scale, &local)
        coder.encodeValue(ofObjCType: &Decimal.Int32Type, at: &size)
        coder.encodeValue(ofObjCType: &Decimal.Int32Type, at: &scale)
        coder.encodeArray(ofObjCType: &Decimal.UInt8Type, count: Int(size), at: &bytes)
    }
    
}

//
// Declaration of the power (**) operator
//

infix operator ** : ExponentPrecedence
infix operator **= : ExponentPrecedence
precedencegroup ExponentPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}

//
// Mathematical operator definitions
//

extension Decimal {
    
    static public func % (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.remainder(rhs) }
    static public func * (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.mul(rhs) }
    static public func + (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.add(rhs) }
    static public func / (lhs: Decimal, rhs: Decimal) -> Decimal { return lhs.div(rhs) }
    static public prefix func + (a: Decimal) -> Decimal { return a }
    
    static public func -= (a: inout Decimal, b: Decimal) { a = a - b }
    static public func += (a: inout Decimal, b: Decimal) { a = a + b }
    static public func *= (a: inout Decimal, b: Decimal) { a = a * b }
    static public func /= (a: inout Decimal, b: Decimal) { a = a / b }
    static public func %= (a: inout Decimal, b: Decimal) { a = a % b }
    static public func **= (a: inout Decimal, b: Decimal) { a = a ** b }
    
    static public func ** (base: Decimal, power: Int) -> Decimal { return base ** Decimal(power) }
    static public func ** (base: Int, power: Decimal) -> Decimal { return Decimal(base) ** power }
    static public func ** (base: Decimal, power: Decimal) -> Decimal { return base.pow(power) }
    
    //
    // Logical operators
    //
    
    static public func & (a: Decimal, b: Decimal) -> Decimal { return a.and(b) }
    static public func | (a: Decimal, b: Decimal) -> Decimal { return a.or(b) }
    static public func ^ (a: Decimal, b: Decimal) -> Decimal { return a.xor(b) }
    static public prefix func ~ (a: Decimal) -> Decimal { return a.not() }
    
    static public func &= (a: inout Decimal, b: Decimal) { a = a & b }
    static public func |= (a: inout Decimal, b: Decimal) { a = a | b }
    static public func ^= (a: inout Decimal, b: Decimal) { a = a ^ b }
    
    static public func << (a: Decimal, b: Decimal) -> Decimal { return a.shift(b.abs) }
    static public func >> (a: Decimal, b: Decimal) -> Decimal { return a.shift(-b.abs) }
    
}


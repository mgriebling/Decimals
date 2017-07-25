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
        "786783165271201909145648566923460348610454326648213393607260249141273724587006", digits: maximumDigits)
    public static let π = pi
    fileprivate static let _2pi = 2 * pi
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
        if uint <= UInt(UInt32.max) && uint >= UInt(UInt32.min)  {
            initContext(digits: Decimal.nominalDigits)
            decNumberFromUInt32(&decimal, UInt32(uint))
        } else {
            /* do this the long way */
            let working = uint
            var x = Decimal(0)
            var n = working
            var m = Decimal(1)
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
        if int <= Int(Int32.max) && int >= Int(Int32.min)  {
            initContext(digits: Decimal.nominalDigits)
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
        self.init(numStr, digits: 38)  // Apple Decimals are 38 digits fixed
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
    
    public func string(withRadix radix : Int) -> String {
        var nlogical = self.logical()
        let radix = Decimal(Swift.min(36, Swift.max(radix, 2))).logical()  // restrict to legal radix values 2 to 36
        var str = ""
        while nlogical > 0 {
            let digit = nlogical % radix
            nlogical = nlogical.idiv(radix)
            str = getRadixDigitFor(digit.base10().int) + str
        }
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
        var a = decimal
        decNumberNormalize(&a, &a, &Decimal.context)
        return Decimal(a)
    }
    
    /// Converts the number to an integer representation without any fractional digits.
    /// The active rounding mode is used during this conversion.
    public func integer () -> Decimal {
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
    
    public func abs () -> Decimal {
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
        var a = self.logical().decimal
        decNumberOr(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func and (_ b: Decimal) -> Decimal {
        var b = b.logical()
        var a = self.logical().decimal
        decNumberAnd(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func xor (_ b: Decimal) -> Decimal {
        var b = b.logical()
        var a = self.logical().decimal
        decNumberXor(&a, &a, &b.decimal, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func not () -> Decimal {
        var a = self.logical().decimal
        decNumberInvert(&a, &a, &Decimal.context)
        return Decimal(a).base10()
    }
    
    public func shift (_ bits: Decimal) -> Decimal {
        var bits = bits
        var a = decimal
        decNumberShift(&a, &a, &bits.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func rotate (_ bits: Decimal) -> Decimal {
        var bits = bits
        var a = decimal
        decNumberRotate(&a, &a, &bits.decimal, &Decimal.context)
        return Decimal(a)
    }
    
    public func logical () -> Decimal {
        // converts decimal numbers to logical
//        let x = self
//        if x.isLogical { return x }
//        let int = x.integer()
//        if int.isLogical { return int }
        
        // do this the painful way
        var y : Decimal = 0
        var n = self.integer().abs()
        var bits : Decimal = 0
        while n > 0 {
            y += (n % 2) << bits
            n = n.idiv(2)
            bits += 1
        }
        return y
    }
    
    public func base10 () -> Decimal {
        // converts logical numbers to decimal
        var x = self
        var scale : Decimal = 1
        var y : Decimal = 0
        while x > 0 {
            let bit = x % 10
            if !bit.isZero {
                y += scale
            }
            x = x.idiv(10)
            scale *= 2
        }
        return y
    }
}

//
// Trigonometric functions
//

extension Decimal {
    
    public static var SINCOS_DIGITS : Int { return 51 }
    
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
        j = 1         // dn_1(&j.n);
        t = 1         // dn_1(&t.n);
        s = 1         // dn_1(&s.n);
        c = 1         // dn_1(&c.n);
        
        var fins = sout == nil
        var finc = cout == nil
        for i in 1..<1000 where !(fins && finc) {
            let odd = (i & 1) != 0
            
            j += 1          // dn_inc(&j.n);
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
            
            j += 1          // dn_inc(&j.n);
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
            cout = c + 0    // dn_plus(cout, &c.n);
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
        let invert = a > 1
        if invert { a = 1 / a } // dn_divide(&a, &const_1, &a);
        
        // Range reduce to small enough limit to use taylor series
        // using:
        //  tan(x/2) = tan(x)/(1+sqrt(1+tan(x)^2))
        for _ in 0..<1000 {
            if a <= Decimal("0.1") { break }
            doubles += 1
            // a = a/(1+sqrt(1+a^2)) -- at most 3 iterations.
            b = a.sqr()     // dn_multiply(&b, &a, &a);
            b += 1          // dn_inc(&b);
            b = b.sqrt()    // dn_sqrt(&b, &b);
            b += 1          // dn_inc(&b);
            a /= b          // dn_divide(&a, &a, &b);
        }
        
        // Now Taylor series
        // tan(x) = x(1-x^2/3+x^4/5-x^6/7...)
        // We calculate pairs of terms and stop when the estimate doesn't change
        res = 3         // , &const_3);
        j = 5           // decNumberCopy(&j, &const_5);
        a2 = a.sqr()    // dn_multiply(&a2, &a, &a);	// a^2
        t = a2          // decNumberCopy(&t, &a2);
        res = t / res   // dn_divide(res, &t, res);	// s = 1-t/3 -- first two terms
        res = 1 - res   // dn_1m(res, res);
        
        repeat {	// Loop until there is no digits changed
            last = res
            
            t *= a2     // dn_multiply(&t, &t, &a2);
            z = t / j   // dn_divide(&z, &t, &j);
            res += z    // dn_add(res, res, &z);
            j += 2      // dn_p2(&j, &j);
            
            t *= a2     // dn_multiply(&t, &t, &a2);
            z = t / j   // dn_divide(&z, &t, &j);
            res += z    // dn_subtract(res, res, &z);
            j += 2      // dn_p2(&j, &j);
        } while res != last
        res *= a        // dn_multiply(res, res, &a);
        
        while doubles > 0 {
            res += res      // dn_add(res, res, res);
            doubles -= 1
        }
        
        if invert {
            res = Decimal.pi/2 - res // dn_subtract(res, &const_PIon2, res);
        }
        
        if neg { res = -res } // dn_minus(res, res);
    }
    
    private static func atan2(y: Decimal, x: Decimal) -> Decimal {
        let xneg = x.isNegative
        let yneg = y.isNegative
        var at : Decimal = 0
        
        if x.isNaN || y.isNaN { at.setNAN(); return at }
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
                        at = 0      // decNumberZero(at);
                    }
                } else if xneg {
                    at = Decimal.pi // decNumberPI(at);
                } else {
                    at = 0      // decNumberZero(at);
                }
            }
            return at
        }
        if x.isZero  {
            at = Decimal.pi/2 // decNumberPIon2(at);
            if yneg { at = -at } //  dn_minus(at, at);
            return at
        }
        if x.isInfinite {
            if xneg {
                if y.isInfinite {
                    at = Decimal.pi * Decimal("0.75")  // decNumberPI(&t);
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
                    at = 0               // decNumberZero(at);
                    if yneg { at = -at } // dn_minus(at, at);
                }
            }
            return at
        }
        if y.isInfinite  {
            at = Decimal.pi/2    // decNumberPIon2(at);
            if yneg { at = -at } //  dn_minus(at, at);
            return at
        }
        
        var t = y / x       // dn_divide(&t, y, x);
        var r : Decimal = 0
        Decimal.atan(res: &r, x: t) // do_atan(&r, &t);
        if xneg {
            t = Decimal.pi // decNumberPI(&t);
            if yneg { t = -t } // dn_minus(&t, &t);
        } else {
            t = 0 // decNumberZero(&t);
        }
        at = r + t  // dn_add(at, &r, &t);
        if at.isZero && yneg { at = -at } //  dn_minus(at, at);
        return at
    }
    
    private static func asin(res: inout Decimal, x: Decimal) {
        if x.isNaN { res.setNAN(); return }
        
        var abx = x.abs() //dn_abs(&abx, x);
        if abx > 1 { res.setNAN(); return }
        
        // res = 2*atan(x/(1+sqrt(1-x*x)))
        var z = x.sqr() // dn_multiply(&z, x, x);
        z = 1 - z       // dn_1m(&z, &z);
        z = z.sqrt()    // dn_sqrt(&z, &z);
        z += 1          // dn_inc(&z);
        z = x / z       // dn_divide(&z, x, &z);
        Decimal.atan(res: &abx, x: z) // do_atan(&abx, &z);
        res = 2 * abx   // dn_mul2(res, &abx);
    }
    
    private static func acos(res: inout Decimal, x: Decimal) {
        if x.isNaN { res.setNAN(); return }
        
        var abx = x.abs() //dn_abs(&abx, x);
        if abx > 1 { res.setNAN(); return }
        
        // res = 2*atan((1-x)/sqrt(1-x*x))
        if x == 1 {
            res = 0
        } else {
            var z = x.sqr() // dn_multiply(&z, x, x);
            z = 1 - z       // dn_1m(&z, &z);
            z = z.sqrt()    // dn_sqrt(&z, &z);
            abx = 1 - x     // dn_1m(&abx, x);
            z = abx / z     // dn_divide(&z, &abx, &z);
            Decimal.atan(res: &abx, x: z) // do_atan(&abx, &z);
            res = 2 * abx   // dn_mul2(res, &abx);
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
        var x2 : Decimal = 0
        var res : Decimal? = 0
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            if Decimal.convertToRadians(res: &x2, x: x, r0: 0, r1: 1, r2: 0, r3: 1) {
                var Nil : Decimal? = nil
                Decimal.sincosTaylor(x2, sout: &res, cout: &Nil)  // sincosTaylor(&x2, res, NULL);
            } else {
                res = x2  // decNumberCopy(res, &x2);
            }
        }
        return res!
    }
    
    public func cos() -> Decimal {
        let x = self
        var x2 : Decimal = 0
        var res : Decimal? = 0
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            if Decimal.convertToRadians(res: &x2, x: x, r0:1, r1:0, r2:1, r3:0) {
                var Nil : Decimal? = nil
                Decimal.sincosTaylor(x2, sout: &Nil, cout: &res)
            } else {
                res = x2  // decNumberCopy(res, &x2);
            }
        }
        return res!
    }
    
    public func tan() -> Decimal {
        let x = self
        var x2 : Decimal = 0
        var res : Decimal? = 0
        var NaN : Decimal { var x = Decimal(0); x.setNAN(); return x }
        
        if x.isSpecial {
            res!.setNAN()
        } else {
            let digits = Decimal.digits
            Decimal.digits = Decimal.SINCOS_DIGITS
            if Decimal.convertToRadians(res: &x2, x: x, r0:0, r1:NaN, r2:0, r3:NaN) {
                var s, c : Decimal?
                Decimal.sincosTaylor(x2, sout: &s, cout: &c)
                x2 = s! / c!  // dn_divide(&x2.n, &s.n, &c.n);
            }
            Decimal.digits = digits
            res = x2 + 0 // dn_plus(res, &x2.n);
        }
        return res!
    }
    
    public func arcSin() -> Decimal {
        var res : Decimal = 0
        Decimal.asin(res: &res, x: self)
        Decimal.convertFromRadians(res: &res, x: res)
        return res
    }
    
    public func arcCos() -> Decimal {
        var res : Decimal = 0
        Decimal.acos(res: &res, x: self)
        Decimal.convertFromRadians(res: &res, x: res)
        return res
    }
    
    public func arcTan() -> Decimal {
        let x = self
        var z : Decimal = 0
        if x.isSpecial {
            if x.isNaN {
                return x
            } else {
                z = Decimal.pi/2
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
        var v = u - 1
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
            if x.abs() < 0.5 {
                var u = Expm1(x)
                let t = u / 2   // dn_div2(&t, &u);
                u += 1          // dn_inc(&u);
                let v = t / u   // dn_divide(&v, &t, &u);
                u += 1          // dn_inc(&u);
                sinhv = u * v   // dn_multiply(sinhv, &u, &v);
            } else {
                let u = x.exp() // dn_exp(&u, x);			// u = e^x
                let v = 1 / u   // decNumberRecip(&v, &u);		// v = e^-x
                let t = u - v   // dn_subtract(&t, &u, &v);	// r = e^x - e^-x
                sinhv = t / 2           // dn_div2(sinhv, &t);
            }
        }
        if coshv != nil {
            let u = x.exp() // dn_exp(&u, x);			// u = e^x
            let v = 1 / u   // decNumberRecip(&v, &u);		// v = e^-x
            coshv = (u + v) / 2 // dn_average(coshv, &v, &u);	// r = (e^x + e^-x)/2
        }
    }
    
    public func sinh() -> Decimal {
        let x = self
        if x.isSpecial {
            if x.isNaN { return x }
            return x
        }
        var res : Decimal? = 0
        var Nil : Decimal? = nil
        Decimal.sinhcosh(x: x, sinhv: &res, coshv: &Nil)
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
        var res : Decimal? = 0
        if x.isSpecial {
            if x.isNaN { return x }
            res!.setINF()
            return res!
        }
        var Nil : Decimal? = nil
        Decimal.sinhcosh(x: x, sinhv: &Nil, coshv: &res)
        return res!
    }
    
    public func tanh() -> Decimal {
        let x = self
        if x.isNaN { return x }
        if x < 100 {
            if x.isNegative { return -1 }
            return 1
        }
        var a = x.sqr()     // dn_add(&a, x, x);
        let b = a.exp()-1   // decNumberExpm1(&b, &a);
        a = b + 2           // dn_p2(&a, &b);
        return b / a
    }
    
    /* ln(1+x) */
    private func Ln1p() -> Decimal {
        let x = self
        if x.isSpecial || x.isZero {
            return x
        }
        let u = x + 1
        var v = u - 1
        if v == 0 { return x }
        let w = x / v // dn_divide(&w, x, &v);
        v = u.ln()
        return v * w
    }
    
    public func arcSinh() -> Decimal {
        let x = self
        var y = x.sqr()         // decNumberSquare(&y, x);		// y = x^2
        var z = y + 1           // dn_p1(&z, &y);			// z = x^2 + 1
        y = z.sqrt() + 1        // dn_sqrt(&y, &z);		// y = sqrt(x^2+1)
        z = x / y + 1           // dn_divide(&z, x, &y);
        y = x * z               // dn_multiply(&y, x, &z);
        return y.Ln1p()
    }
    
    
    public func arcCosh() -> Decimal {
        let x = self
        var res = x.sqr()   // decNumberSquare(res, x);	// r = x^2
        var z = res - 1     // dn_m1(&z, res);			// z = x^2 + 1
        res = z.sqr()       // dn_sqrt(res, &z);		// r = sqrt(x^2+1)
        z = res + x         // dn_add(&z, res, x);		// z = x + sqrt(x^2+1)
        return z.ln()
    }
    
    public func arcTanh() -> Decimal {
        let x = self
        var res : Decimal = 0
        if x.isNaN { return x }
        var y = x.abs()
        if y == 1 {
            if x.isNegative { res.setNINF(); return res }
            res.setINF(); return res
        }
        // Not the obvious formula but more stable...
        var z = x - 1   // dn_1m(&z, x);
        y = x / z       // dn_divide(&y, x, &z);
        z = 2 * y       // dn_mul2(&z, &y);
        y = z.Ln1p()    // decNumberLn1p(&y, &z);
        return y / 2
    }

}

//
// Combination/Permutation functions
//

extension Decimal {
    
    private enum permOpts { case invalid, intg, normal }
    private static var DUMP : Bool { return false }  // set true to dump gamma calculations
    
    private static var constGammaR : Decimal   { return Decimal("23.118910" , digits: maximumDigits) }
    private static var constGammaC00 : Decimal { return Decimal("2.5066282746310005024157652848102462181924349228522", digits: maximumDigits) }
    private static var constGammaC01 : Decimal { return Decimal("18989014209.359348921215164214894448711686095466265", digits: maximumDigits) }
    private static var constGammaC02 : Decimal { return Decimal("-144156200090.5355882360184024174589398958958098464", digits: maximumDigits) }
    private static var constGammaC03 : Decimal { return Decimal("496035454257.38281370045894537511022614317130604617", digits: maximumDigits) }
    private static var constGammaC04 : Decimal { return Decimal("-1023780406198.473219243634817725018768614756637869", digits: maximumDigits) }
    private static var constGammaC05 : Decimal { return Decimal("1413597258976.513273633654064270590550203826819201", digits: maximumDigits) }
    private static var constGammaC06 : Decimal { return Decimal("-1379067427882.9183979359216084734041061844225060064", digits: maximumDigits) }
    private static var constGammaC07 : Decimal { return Decimal("978820437063.87767271855507604210992850805734680106", digits: maximumDigits) }
    private static var constGammaC08 : Decimal { return Decimal("-512899484092.42962331637341597762729862866182241859", digits: maximumDigits) }
    private static var constGammaC09 : Decimal { return Decimal("199321489453.70740208055366897907579104334149619727", digits: maximumDigits) }
    private static var constGammaC10 : Decimal { return Decimal("-57244773205.028519346365854633088208532750313858846", digits: maximumDigits) }
    private static var constGammaC11 : Decimal { return Decimal("12016558063.547581575347021769705235401261600637635", digits: maximumDigits) }
    private static var constGammaC12 : Decimal { return Decimal("-1809010182.4775432310136016527059786748432390309824", digits: maximumDigits) }
    private static var constGammaC13 : Decimal { return Decimal("189854754.19838668942471060061968602268245845778493", digits: maximumDigits) }
    private static var constGammaC14 : Decimal { return Decimal("-13342632.512774849543094834160342947898371410759393", digits: maximumDigits) }
    private static var constGammaC15 : Decimal { return Decimal("593343.93033412917147656845656655196428754313318006", digits: maximumDigits) }
    private static var constGammaC16 : Decimal { return Decimal("-15403.272800249452392387706711012361262554747388558", digits: maximumDigits) }
    private static var constGammaC17 : Decimal { return Decimal("207.44899440283941314233039147731732032900399915969", digits: maximumDigits) }
    private static var constGammaC18 : Decimal { return Decimal("-1.2096284552733173049067753842722246474652246301493", digits: maximumDigits) }
    private static var constGammaC19 : Decimal { return Decimal(".0022696111746121940912427376548970713227810419455318", digits: maximumDigits) }
    private static var constGammaC20 : Decimal { return Decimal("-.00000079888858662627061894258490790700823308816322084001", digits: maximumDigits) }
    private static var constGammaC21 : Decimal { return Decimal(".000000000016573444251958462210600022758402017645596303687465", digits: maximumDigits) }
    
    private static var gammaConsts : [Decimal] = [
        constGammaC01, constGammaC02, constGammaC03,
        constGammaC04, constGammaC05, constGammaC06,
        constGammaC07, constGammaC08, constGammaC09,
        constGammaC10, constGammaC11, constGammaC12,
        constGammaC13, constGammaC14, constGammaC15,
        constGammaC16, constGammaC17, constGammaC18,
        constGammaC19, constGammaC20, constGammaC21,
    ]
    
    static private func Dump(_ r: Decimal, _ s: String) {
        if DUMP {
            print(s + "=\(r)")
        }
    }
    
    static private func LnGamma(_ x: Decimal) -> Decimal {
        Dump(x, "z")
        var s : Decimal = 0             // decNumberZero(&s);
        var t = x + 21                  // dn_add(&t, x, &const_21);
        for k in (0...20).reversed() {  // (k = 20; k >= 0; k--) {
            let u = gammaConsts[k] / t  // dn_divide(&u, gamma_consts[k], &t);
            t -= 1                      // dn_dec(&t);
            s += u                      // dn_add(&s, &s, &u);
        }
        t = s + constGammaC00           // dn_add(&t, &s, &const_gammaC00);
        s = t.ln()                      // dn_ln(&s, &t);
        Dump(t, "sum")
        Dump(s, "ln")
        
        //		r = z + g + .5;
        let r = x + constGammaR         // dn_add(&r, x, &const_gammaR)
        Dump(r, "r")
        
        //		r = log(R[0][0]) + (z+.5) * log(r) - r;
        var u = r.ln()                  // dn_ln(&u, &r);
        t = x + 0.5                     // dn_add(&t, x, &const_0_5);
        let v = u * t                   // dn_multiply(&v, &u, &t);
        Dump(v, "(z+.5)*log(r)")
        
        u = v - r                       // dn_subtract(&u, &v, &r);
        let res = u + s                 // dn_add(res, &u, &s);
        
        Dump(res, "res")
        return res
    }
    
    static private func lnGamma(_ xin: Decimal) -> Decimal {
        var reflec = false
        var res: Decimal = 0
        
        // Check for special cases
        if xin.isSpecial {
            if xin.isInfinite && !xin.isNegative { return xin }
            res.setNAN(); return res
        }
        
        // Correct out argument and begin the inversion if it is negative
        var x : Decimal
        if xin <= 0 {
            reflec = true
            let t = 1 - xin         // dn_1m(&t, xin);
            if t.isInteger {
                res.setNAN(); return res
            }
            x = t - 1               // dn_m1(&x, &t);
        } else {
            x = xin - 1             // dn_m1(&x, xin);
        }
        
        res = LnGamma(x)
        
        // Finally invert if we started with a negative argument
        if reflec {
            // Figure out S * PI mod 2PI
            var u = xin % 2             // decNumberMod(&u, xin, &const_2);
            var t = u * pi              // dn_mulPI(&t, &u);
            t = x.sin()                 // sincosTaylor(&t, &x, NULL);
            u = pi / x                  // dn_divide(&u, &const_PI, &x);
            t = u.ln()                  // dn_ln(&t, &u);
            res = t - res               // dn_subtract(res, &t, res);
        }
        return res
    }
    
    static private func permHelper(_ r: inout Decimal, x: Decimal, y: Decimal) -> permOpts {
        if x.isSpecial || y.isSpecial || x.isNegative || y.isNegative {
            if x.isInfinite && !y.isInfinite {
                r.setINF()
            } else {
                r.setNAN()
            }
            return .invalid
        }
        var n = x + 1           // dn_p1(&n, x);				// x+1
        let s = lnGamma(n)      // lnGamma(x+1) = Ln x!
        
        r = n - y               // dn_subtract(r, &n, y);	// x-y+1
        if r <= 0 {
            r.setNAN()
            return .invalid
        }
        n = lnGamma(r)          // decNumberLnGamma(&n, r);		// LnGamma(x-y+1) = Ln (x-y)!
        r = s - n               // dn_subtract(r, &s, &n);
        
        if x.isInteger && y.isInteger { return .intg }
        return .normal
    }
    
    /* Calculate permutations:
     * C(x, y) = P(x, y) / y! = x! / ( (x-y)! y! )
     */
    public func comb (y: Decimal) -> Decimal {
        var r : Decimal = 0
        let code = Decimal.permHelper(&r, x: self, y: y)
        if code != .invalid {
            var n = y + 1
            let s = Decimal.lnGamma(n)      // lnGamma(y+1) = Ln y!
            n = r - s
            var res = n.exp()
            if code == .intg { res = res.integer() }
            return res
        } else {
            return r
        }
    }
    
    /* Calculate permutations:
     * P(x, y) = x! / (x-y)!
     */
    public func perm (y: Decimal) -> Decimal {
        var t : Decimal = 0
        let code = Decimal.permHelper(&t, x: self, y: y)
        if code != .invalid {
            var res = t.exp()                           // dn_exp(res, &t);
            if code == .intg { res = res.integer() }
            return res
        } else {
            return t
        }
    }
    
    public func gamma () -> Decimal {
        var reflec = false
        var res : Decimal = 0
        let xin = self
        
        // Check for special cases
        if xin.isSpecial {
            if xin.isInfinite && !xin.isNegative { return xin }
            res.setNAN(); return res
        }
        
        // Correct our argument and begin the inversion if it is negative
        var x : Decimal
        if xin <= 0 {
            reflec = true
            let t = 1 - xin  // dn_1m(&t, xin);
            if t.isInteger {
                res.setNAN(); return res
            }
            x = t - 1  // dn_m1(&x, &t);
        } else {
            x = xin - 1 // dn_m1(&x, xin);
            
            // Provide a fast path evaluation for positive integer arguments that aren't too large
            // The threshold for overflow is 205! (i.e. 204! is within range and 205! isn't).
            // Without introducing a new constant, we've got 150 or 256 to choose from.
            if x.isInteger && !xin.isZero && x < 256 {
                res = 1
                while x != 0 {
                    res *= x        // dn_multiply(res, res, &x);
                    x -= 1          // dn_m1(&x, &x);
                }
                return res
            }
        }
        
        let t = Decimal.LnGamma(x)  // dn_LnGamma(&t, &x);
        res = t.exp()               // dn_exp(res, &t);
        
        // Finally invert if we started with a negative argument
        if reflec {
            // Figure out xin * PI mod 2PI
            var u = xin % 2             // decNumberMod(&u, xin, &const_2);
            let t = u * Decimal.pi      // dn_mulPI(&t, &u);
            let s = t.sin()             // sincosTaylor(&t, &x, NULL);
            u = s * res
            res = Decimal.pi / u        // dn_divide(&u, &const_PI, &x);
        }
        return res
    }
    
    public func factorial () -> Decimal {
        let x = self + 1
        return x.gamma()
    }
    
}

//
// Add global support for abs().
//

extension Decimal : AbsoluteValuable {
    
    public static func abs (_ a: Decimal) -> Decimal {
        return a.abs()
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
    
    public init(floatLiteral value: Double) { self.init(String(value)) }  // not exactly representable anyway so we cheat
    
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
    public init (stringLiteral s: String) { self.init(s) }
    public init (extendedGraphemeClusterLiteral s: ExtendedGraphemeClusterLiteralType) { self.init(stringLiteral:s) }
    public init (unicodeScalarLiteral s: UnicodeScalarLiteralType) { self.init(stringLiteral:"\(s)") }
    
}

//
// Convenience functions
//

extension Decimal : RealOperations {
    
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

infix operator *+ : MultiplicationPrecedence

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
    
    static public func << (a: Decimal, b: Decimal) -> Decimal { return a.shift(b.abs()) }
    static public func >> (a: Decimal, b: Decimal) -> Decimal { return a.shift(-b.abs()) }
    
}


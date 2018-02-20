//
//  complex.swift
//  complex
//
//  Created by Dan Kogai on 6/12/14.
//  Copyright (c) 2014 Dan Kogai. All rights reserved.
//

import Foundation

// protocol RealType : FloatingPointType // sadly crashes as of Swift 1.1 :-(
public protocol RealType {
    
    // copied from FloatingPointType
    init(_ value: UInt8)
    init(_ value: Int8)
    init(_ value: UInt16)
    init(_ value: Int16)
    init(_ value: UInt32)
    init(_ value: Int32)
    init(_ value: UInt64)
    init(_ value: Int64)
    init(_ value: UInt)
    init(_ value: Int)
    init(_ value: Double)
    init(_ value: Float)
    
    // for StringLiteralConvertible support
    init?(_ value: String)
    
    // class vars are now gone 
    // because they will be static vars in Swift 1.2, 
    // making them incompatible to one another
//    static var infinity: Self { get }
//    static var NaN: Self { get }
//    static var quietNaN: Self { get }
    
    var floatingPointClass: FloatingPointClassification { get }
    var isSignMinus: Bool { get }
    var isNormal: Bool { get }
    var isFinite: Bool { get }
    var isZero: Bool { get }
    var isSubnormal: Bool { get }
    var isInfinite: Bool { get }
    var isNaN: Bool { get }
    var isSignaling: Bool { get }
    // copied from Hashable
    var hashValue: Int { get }
    
    // Built-in operators
    static func ==(_: Self, _: Self)->Bool
    static func !=(_: Self, _: Self)->Bool
    static func < (_: Self, _: Self)->Bool
    static func <= (_: Self, _: Self)->Bool
    static func > (_: Self, _: Self)->Bool
    static func >= (_: Self, _: Self)->Bool
    static prefix func + (_: Self)->Self
    static prefix func - (_: Self)->Self
    static func + (_: Self, _: Self)->Self
    static func - (_: Self, _: Self)->Self
    static func * (_: Self, _: Self)->Self
    static func / (_: Self, _: Self)->Self
    static func += (_: inout Self, _: Self)
    static func -= (_: inout Self, _: Self)
    static func *= (_: inout Self, _: Self)
    static func /= (_: inout Self, _: Self)
    
    // methodized functions for protocol's sake
    var abs:Self { get }
    func cos()->Self
    func exp()->Self
    func ln()->Self
    func sin()->Self
    func sqrt()->Self
    func cbrt()->Self
    func hypot(_: Self)->Self
    func atan2(_: Self)->Self
    func pow(_: Self)->Self
    
//    static var LN10:Self { get }
//    static var epsilon:Self { get }
}

//// Double is default since floating-point literals are Double by default
//extension Double : RealType {
//
//    public var abs:Double { return Swift.abs(self) }
//    public func cos()->Double { return Foundation.cos(self) }
//    public func exp()->Double { return Foundation.exp(self) }
//    public func ln()->Double { return Foundation.log(self) }
//    public func sin()->Double { return Foundation.sin(self) }
//    public func sqrt()->Double { return Foundation.sqrt(self) }
//    public func sqrt()->Double { return Foundation.sqrt(self) }
//    public func atan2(_ y:Double)->Double { return Foundation.atan2(self, y) }
//    public func hypot(_ y:Double)->Double { return Foundation.hypot(self, y) }
//    public func pow(_ y:Double)->Double { return Foundation.pow(self, y) }
//    
//    public var isSignMinus: Bool { return self.sign == .minus }
//    public var isSignaling: Bool { return self.isSignalingNaN }
//    
//    // these ought to be static let
//    // but give users a chance to overwrite it
//    static var PI = 3.14159265358979323846264338327950288419716939937510
//    static var π = PI
//    static var E =  2.718281828459045235360287471352662497757247093699
//    static var e = E
//    static var LN2 = 0.6931471805599453094172321214581765680755001343602552
//    static var LOG2E = 1 / LN2
//    static var LN10 = 2.3025850929940456840179914546843642076011014886287729
//    static var LOG10E = 1/LN10
//    static var SQRT2 = 1.4142135623730950488016887242096980785696718753769480
//    static var SQRT1_2 = 1/SQRT2
//    static var epsilon = 0x1p-52
//    /// self * 1.0i
//    var i:Complex<Double>{ return Complex<Double>(0.0, self) }
//}
//
//// But when explicitly typed you can use Float
//extension Float : RealType {
//    public var abs:Float { return Swift.abs(self) }
//    public func cos()->Float { return Foundation.cos(self) }
//    public func exp()->Float { return Foundation.exp(self) }
//    public func ln()->Float { return Foundation.logf(self) }
//    public func sin()->Float { return Foundation.sin(self) }
//    public func sqrt()->Float { return Foundation.sqrt(self) }
//    public func hypot(_ y:Float)->Float { return Foundation.hypot(self, y) }
//    public func atan2(_ y:Float)->Float { return Foundation.atan2(self, y) }
//    public func pow(_ y:Float)->Float { return Foundation.pow(self, y) }
//    
//    public var isSignMinus: Bool { return self.sign == .minus }
//    public var isSignaling: Bool { return self.isSignalingNaN }
//    
//    // these ought to be static let
//    // but give users a chance to overwrite it
//    static var PI:Float = 3.14159265358979323846264338327950288419716939937510
//    static var π:Float = PI
//    static var E:Float =  2.718281828459045235360287471352662497757247093699
//    static var e:Float = E
//    static var LN2:Float = 0.6931471805599453094172321214581765680755001343602552
//    static var LOG2E:Float = 1 / LN2
//    static var LN10:Float = 2.3025850929940456840179914546843642076011014886287729
//    static var LOG10E:Float = 1/LN10
//    static var SQRT2:Float = 1.4142135623730950488016887242096980785696718753769480
//    static var SQRT1_2:Float = 1/SQRT2
//    static var epsilon:Float = 0x1p-23
//    /// self * 1.0i
//    var i:Complex<Float>{ return Complex<Float>(0.0 as Float, self) }
//}

// el corazon
public struct Complex<T:RealType>  {
	fileprivate var re:T
	fileprivate var im:T
	
    public init(_ re:T, _ im:T = T(0)) {
        self.re = re
        self.im = im
    }
    public init() { self.init(T(0)) }
    public init(abs:T, arg:T) {
        self.re = abs * arg.cos()
        self.im = abs * arg.sin()
    }
    /// real part thereof
    public var real:T { get{ return re } set(r){ re = r } }
    
    /// imaginary part thereof
    public var imag:T { get{ return im } set(i){ im = i } }
    
    /// absolute value thereof
    public var abs:T {
        get { return re.hypot(im) }
        set(r){ let f = r / abs; re *= f; im *= f }
    }
    
    /// argument thereof
    public var arg:T  {
        get { return im.atan2(re) }
        set(t){ let m = abs; re = m * t.cos(); im = m * t.sin() }
    }
    
    /// norm thereof
    public var norm:T { return re.hypot(im) }
    /// conjugate thereof
    public var conj:Complex { return Complex(re, -im) }
    /// projection thereof
    public var proj:Complex {
        if re.isFinite && im.isFinite {
            return self
        } else {
            return Complex(
                T(1)/T(0), im.isSignMinus ? -T(0) : T(0)
            )
        }
    }
    /// (real, imag)
    public var tuple:(T, T) {
        get { return (re, im) }
        set(t){ (re, im) = t}
    }
    
    /// z * i
    public var i:Complex { return Complex(-im, re) }
    
}

// operator definitions
// ** operator is defined in Decimal file
infix operator =~ : ComparisonPrecedence  // { associativity none precedence 130 }
infix operator !~ : ComparisonPrecedence  // { associativity none precedence 130 }

extension Complex : Equatable {
    // != is auto-generated thanks to Equatable
    public static func == (lhs:Complex<T>, rhs:Complex<T>) -> Bool {
        return lhs.re == rhs.re && lhs.im == rhs.im
    }
}

extension Complex : Hashable {
    /// .hashvalue -- conforms to Hashable
    public var hashValue:Int { // take most significant halves and join
        let bits = MemoryLayout<Int>.size * 4
        let mask = bits == 16 ? 0xffff : 0xffffFFFF
        return (re.hashValue & ~mask) | (im.hashValue >> bits)
    }
}

extension Complex : CustomStringConvertible {
    /// Conforms to CustomStringConvertible protocol
    public var description: String {
        let isOne = im.abs == 1
        let plus = im.isSignMinus ? isOne ? "-" : "" : "+"
        let imag = im.isZero ? "" : isOne ? "\(plus)i" : "\(plus)\(im)i"
        return "\(re)\(imag)"
    }
}

extension Complex : ExpressibleByFloatLiteral {
    /// Conforms to ExpressibleByFloatLiteral protocol
    public init(floatLiteral re:Double) {
        im = T(0)
        self.re = T(re)
    }
}

extension Complex : ExpressibleByIntegerLiteral {
    /// Conforms to ExpressibleByIntegerLiteral protocol
    public init(integerLiteral re:Int) {
        im = T(0)
        self.re = T(re)
    }
}

extension Complex : ExpressibleByStringLiteral {
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = Character
    
    //
    // StringLiteralConvertible protocol
    //
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }
    
    //
    // StringLiteralConvertible protocol
    //
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: "\(value)")
    }
    
    //
    // StringLiteralConvertible protocol
    //
    public init(stringLiteral s: String) {
        var vs = s.replacingOccurrences(of: " ", with: "").lowercased()  // remove all spaces & make lowercase
        var number = ""
        var inumber = ""
        let imaginary = "i"
        
        func processNumber() {
            if let _ = vs.range(of: imaginary) {
                inumber = number + vs 	// transfer the sign
                number = ""				// clear the real part
            } else {
                number += vs			// copy the number
            }
        }
        
        self.init()
        if !vs.isEmpty {
            // break apart the string into real and imaginary pieces
            let signChars = CharacterSet(charactersIn: "+-")
            let exponent = "e"
            var ch = vs[vs.startIndex]
            var iPresent = false
            
            // remove leading sign -- if any
            if signChars.contains(UnicodeScalar(String(ch))!) {
                number.append(ch); ch = vs.remove(at: vs.startIndex)
            }
            if let range = vs.rangeOfCharacter(from: signChars) {
                // check if this is an exponent
                if let expRange = vs.range(of: exponent), expRange.lowerBound == range.lowerBound {
                    // search beyond the exponent
                    let start = vs.index(after: range.lowerBound)
                    let newRange = Range(uncheckedBounds: (start, vs.endIndex))
                    if let range = vs.rangeOfCharacter(from: signChars, options: [], range: newRange) {
                        // This is likely the start of the second number
                        number += vs[...vs.index(before:range.lowerBound)]
                        inumber = String(vs[range.lowerBound...])
                    } else {
                        // Only one number exists
                        processNumber()
                    }
                } else {
                    // This is the start of the second number
                    number += vs[...vs.index(before:range.lowerBound)]
                    inumber = String(vs[range.lowerBound...])
                }
            } else {
                // only one number exists
                processNumber()
            }

            re = T(number)!
            iPresent = !inumber.isEmpty
            inumber = inumber.replacingOccurrences(of: imaginary, with: "") // remove the "i"
            
            // account for solitary "i"
            if iPresent {
                if inumber.isEmpty { inumber = "1" }
                else if inumber == "+" || inumber == "-" { inumber += "1" }
            }
            im = T(inumber)!
        }
    }

}

public extension Complex {
    
    static public func == (lhs:Complex<T>, rhs:T) -> Bool {
        return lhs.re == rhs && lhs.im.isZero
    }
    static public func == (lhs:T, rhs:Complex<T>) -> Bool {
        return rhs.re == lhs && rhs.im.isZero
    }
    
    // +, +=
    static public prefix func + (z:Complex<T>) -> Complex<T> {
        return z
    }
    static public func + (lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
        return Complex(lhs.re + rhs.re, lhs.im + rhs.im)
    }
    static public func + (lhs:Complex<T>, rhs:T) -> Complex<T> {
        return lhs + Complex(rhs)
    }
    static public func + (lhs:T, rhs:Complex<T>) -> Complex<T> {
        return Complex(lhs) + rhs
    }
    static public func += (lhs:inout Complex<T>, rhs:Complex<T>) {
        lhs.re += rhs.re; lhs.im += rhs.im
    }
    static public func += (lhs:inout Complex<T>, rhs:T) {
        lhs.re += rhs
    }
    
    // -, -=
    static public prefix func - (z:Complex<T>) -> Complex<T> {
        return Complex<T>(-z.re, -z.im)
    }
    static public func - (lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
        return Complex(lhs.re - rhs.re, lhs.im - rhs.im)
    }
    static public func - (lhs:Complex<T>, rhs:T) -> Complex<T> {
        return lhs - Complex(rhs)
    }
    static public func - (lhs:T, rhs:Complex<T>) -> Complex<T> {
        return Complex(lhs) - rhs
    }
    static public func -= (lhs:inout Complex<T>, rhs:Complex<T>) {
        lhs.re -= rhs.re ; lhs.im -= rhs.im
    }
    static public func -= (lhs:inout Complex<T>, rhs:T) {
        lhs.re -= rhs
    }
    
    // *, *=
    static public func * (lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
        return Complex(
            lhs.re * rhs.re - lhs.im * rhs.im,
            lhs.re * rhs.im + lhs.im * rhs.re
        )
    }
    static public func * (lhs:Complex<T>, rhs:T) -> Complex<T> {
        return Complex(lhs.re * rhs, lhs.im * rhs)
    }
    static public func * (lhs:T, rhs:Complex<T>) -> Complex<T> {
        return Complex(lhs * rhs.re, lhs * rhs.im)
    }
    static public func *= (lhs:inout Complex<T>, rhs:Complex<T>) {
        lhs = lhs * rhs
    }
    static public func *= (lhs:inout Complex<T>, rhs:T) {
        lhs = lhs * rhs
    }
    
    // /, /=
    //
    // cf. https://github.com/dankogai/swift-complex/issues/3
    //
    static public func / (lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
        if rhs.re.abs >= rhs.im.abs {
            let r = rhs.im / rhs.re
            let d = rhs.re + rhs.im * r
            return Complex (
                (lhs.re + lhs.im * r) / d,
                (lhs.im - lhs.re * r) / d
            )
        } else {
            let r = rhs.re / rhs.im
            let d = rhs.re * r + rhs.im
            return Complex (
                (lhs.re * r + lhs.im) / d,
                (lhs.im * r - lhs.re) / d
            )
            
        }
    }
    static public func / (lhs:Complex<T>, rhs:T) -> Complex<T> {
        return Complex(lhs.re / rhs, lhs.im / rhs)
    }
    static public func / (lhs:T, rhs:Complex<T>) -> Complex<T> {
        return Complex(lhs) / rhs
    }
    static public func /= (lhs:inout Complex<T>, rhs:Complex<T>) {
        lhs = lhs / rhs
    }
    static public func /= (lhs:inout Complex<T>, rhs:T) {
        lhs = lhs / rhs
    }
    
    // exp(z)
    static public func exp(_ z:Complex<T>) -> Complex<T> {
        let abs = z.re.exp()
        let arg = z.im
        return Complex(abs * arg.cos(), abs * arg.sin())
    }
    
    // ln(z)
    static public func ln(_ z:Complex<T>) -> Complex<T> {
        return Complex(z.abs.ln(), z.arg)
    }
    
    // log10(z) -- just because C++ has it
    static public func log10(_ z:Complex<T>) -> Complex<T> { return ln(z)/T(10).ln() }
    static public func log10(_ r:T) -> Complex<T> { return log10(Complex(r)) }
    
    // pow(b, x)
    static public func pow(_ lhs:Complex<T>, _ rhs:Complex<T>) -> Complex<T> {
        if lhs == T(0) { return 1 } // 0 ** 0 == 1
        let z = ln(lhs) * rhs
        return exp(z)
    }
    static public func pow(_ lhs:Complex<T>, _ rhs:T) -> Complex<T> {
        return pow(lhs, Complex(rhs))
    }
    static public func pow(_ lhs:T, _ rhs:Complex<T>) -> Complex<T> {
        return pow(Complex(lhs), rhs)
    }
    
    // **, **=
    static public func ** (lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
        return pow(lhs, rhs)
    }
    static public func ** (lhs:T, rhs:Complex<T>) -> Complex<T> {
        return pow(lhs, rhs)
    }
    static public func ** (lhs:Complex<T>, rhs:T) -> Complex<T> {
        return pow(lhs, rhs)
    }
    static public func **= (lhs:inout Complex<T>, rhs:Complex<T>) {
        lhs = pow(lhs, rhs)
    }
    static public func **= (lhs:inout Complex<T>, rhs:T) {
        lhs = pow(lhs, rhs)
    }
    
    // sqrt(z)
    static public func sqrt(_ z:Complex<T>) -> Complex<T> {
        // return z ** 0.5
        let d = z.re.hypot(z.im)
        let re = ((z.re + d)/T(2)).sqrt()
        if z.im.isSignMinus {
            return Complex(re, -((-z.re + d)/T(2)).sqrt())
        } else {
            return Complex(re,  ((-z.re + d)/T(2)).sqrt())
        }
    }
    // cbrt(z)
    static public func cbrt(_ z:Complex<T>) -> Complex<T> {
        // return z ** 1/3
        let d = z.re.hypot(z.im)
        let re = ((z.re + d)/T(3)).cbrt()
        if z.im.isSignMinus {
            return Complex(re, -((-z.re + d)/T(3)).cbrt())
        } else {
            return Complex(re,  ((-z.re + d)/T(3)).cbrt())
        }
    }
    // cos(z)
    static public func cos(_ z:Complex<T>) -> Complex<T> {
        // return (exp(i*z) + exp(-i*z)) / 2
        return (exp(z.i) + exp(-z.i)) / 2
    }
    // sin(z)
    static public func sin(_ z:Complex<T>) -> Complex<T> {
        // return (exp(i*z) - exp(-i*z)) / (2*i)
        return -(exp(z.i) - exp(-z.i)).i / 2
    }
    // tan(z)
    static public func tan(_ z:Complex<T>) -> Complex<T> {
        // return sin(z) / cos(z)
        let ezi = exp(z.i), e_zi = exp(-z.i)
        return (ezi - e_zi) / (ezi + e_zi).i
    }
    // atan(z)
    static public func atan(_ z:Complex<T>) -> Complex<T> {
        let l0 = ln(1 - z.i), l1 = ln(1 + z.i)
        return (l0 - l1).i / 2
    }
    static public func atan(_ r:T) -> T { return atan(Complex(r)).re }
    // atan2(z, zz)
    static public func atan2(_ z:Complex<T>, _ zz:Complex<T>) -> Complex<T> {
        return atan(z / zz)
    }
    // asin(z)
    static public func asin(_ z:Complex<T>) -> Complex<T> {
        return -ln(z.i + sqrt(1 - z*z)).i
    }
    // acos(z)
    static public func acos(_ z:Complex<T>) -> Complex<T> {
        return ln(z - sqrt(1 - z*z).i).i
    }
    // sinh(z)
    static public func sinh(_ z:Complex<T>) -> Complex<T> {
        return (exp(z) - exp(-z)) / 2
    }
    // cosh(z)
    static public func cosh(_ z:Complex<T>) -> Complex<T> {
        return (exp(z) + exp(-z)) / 2
    }
    // tanh(z)
    static public func tanh(_ z:Complex<T>) -> Complex<T> {
        let ez = exp(z), e_z = exp(-z)
        return (ez - e_z) / (ez + e_z)
    }
    // asinh(z)
    static public func asinh(_ z:Complex<T>) -> Complex<T> {
        return ln(z + sqrt(z*z + 1))
    }
    // acosh(z)
    static public func acosh(_ z:Complex<T>) -> Complex<T> {
        return ln(z + sqrt(z*z - 1))
    }
    // atanh(z)
    static public func atanh(_ z:Complex<T>) -> Complex<T> {
        let t = ln((1 + z)/(1 - z))
        return t / 2
    }
    
    // for the compatibility's sake w/ C++11
    static public func abs<T>(_ z:Complex<T>) -> T { return z.abs }
    static public func arg<T>(_ z:Complex<T>) -> T { return z.arg }
    static public func real<T>(_ z:Complex<T>) -> T { return z.real }
    static public func imag<T>(_ z:Complex<T>) -> T { return z.imag }
    static public func norm<T>(_ z:Complex<T>) -> T { return z.norm }
    static public func conj<T>(_ z:Complex<T>) -> Complex<T> { return z.conj }
    static public func proj<T>(_ z:Complex<T>) -> Complex<T> { return z.proj }
    
    //
    // approximate comparisons
    //
    static private func approx (_ lhs:T, _ rhs:T) -> Bool {
        if lhs == rhs { return true }
        let t = (rhs - lhs) / rhs
        let epsilon = MemoryLayout<T>.size < 8 ? 0x1p-23 : 0x1p-52
        return t.abs <= T(2) * T(epsilon)
    }
    static public func =~ (lhs:Complex<T>, rhs:Complex<T>) -> Bool {
        if lhs == rhs { return true }
        return approx(lhs.abs, rhs.abs)
    }
    static public func =~ (lhs:Complex<T>, rhs:T) -> Bool {
        return approx(lhs.abs, rhs.abs)
    }
    static public func =~ (lhs:T, rhs:Complex<T>) -> Bool {
        return approx(lhs.abs, rhs.abs)
    }
//    static public func !~ (lhs:T, rhs:T) -> Bool {
//        return !(lhs =~ rhs)
//    }
    static public func !~ (lhs:Complex<T>, rhs:Complex<T>) -> Bool {
        return !(lhs =~ rhs)
    }
    static public func !~ (lhs:Complex<T>, rhs:T) -> Bool {
        return !(lhs =~ rhs)
    }
    static public func !~ (lhs:T, rhs:Complex<T>) -> Bool {
        return !(lhs =~ rhs)
    }
    
}

// typealiases
//typealias Complex64 = Complex<Double>
//typealias Complex32 = Complex<Float>



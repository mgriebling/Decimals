//
//  GenericMath.swift
//  Decimals
//
//  Created by Mike Griebling on 8 Sep 2015.
//  Copyright © 2015 Computer Inspirations. All rights reserved.
//

import Foundation

protocol RealOperations : Comparable, ExpressibleByIntegerLiteral {
    func sqrt() -> Self
    static func + (_: Self, _: Self) -> Self
    static func - (_: Self, _: Self) -> Self
    static func * (_: Self, _: Self) -> Self
    static func / (_: Self, _: Self) -> Self
    func sqr () -> Self
    func abs () -> Self
    var eps : Self { get }
    init(_ int : Int)
}

public final class MyDecimal : CustomStringConvertible {
    
    var n: NSDecimalNumber
    
    public var description: String { return n.stringValue }
    
    init(_ n: NSDecimalNumber) { self.n = n }
    
    convenience required public init(integerLiteral value: Int) { self.init(NSDecimalNumber(value: value as Int)) }
    
    var eps : MyDecimal {
        let scale = NSDecimalNumber(mantissa: 1, exponent: 39, isNegative: false)  // 1x10^39 - 1/10 the number of digits
        let leps = n.dividing(by: scale)
        return MyDecimal(leps)
    }
    
}

extension MyDecimal : RealOperations {
    
    public convenience init (_ int: Int) { self.init(NSDecimalNumber(value: int as Int)) }
    public func sqr() -> MyDecimal { return MyDecimal(n.multiplying(by: n)) }
    public func sqrt() -> MyDecimal { return squareRoot(self) }
    public func abs() -> MyDecimal { return self < 0 ? 0 - self : self }

}

public func == (lhs: MyDecimal, rhs: MyDecimal) -> Bool {
    return lhs.n.compare(rhs.n) == .orderedSame
}

public func < (lhs: MyDecimal, rhs: MyDecimal) -> Bool {
    return lhs.n.compare(rhs.n) == .orderedAscending
}

public func * (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.multiplying(by: rhs.n))
}

public func / (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.dividing(by: rhs.n))
}

public func + (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.adding(rhs.n))
}

public func - (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.subtracting(rhs.n))
}

//
// A generic algorithm to calculate a square root to any precision.
//

func squareRoot<T:RealOperations>(_ a: T) -> T {
    if a == 0 { return a }
    
    if a < 0 {
        print("sqrt: Negative argument.")
        return 0
    }
    
    let half = T(1) / 2
    var r = 1 / a
    let h = a * half
    
    let max_iter = 20
    var rold = r
    for _ in 1...max_iter {
        rold = r
        r = r + (half - h * r.sqr()) * r
//        print("Iteration \(i) : \(r*a)")
        if (r - rold).abs() < 2*r.eps { break }
    }
    
    r = r * a
    return r
}

//
// A generic algorithm to calculate pi to any precision.
//

func computePi<T:RealOperations>() -> T {
    // Uses Borwein Quartic Formula for Pi
    var a, y, p, r, pold: T
    var m: Int
    let max_iter = 20
    let two : T = 2
    let sqrt2 = two.sqrt()
    
    a = 6 - 4 * sqrt2
    y = sqrt2 - 1
    m = 2
    
    p = 1 / a
    
    for _ in 1...max_iter {
        m *= 4
        r = (1 - y.sqr().sqr()).sqrt().sqrt()
        y = (1 - r) / (1 + r)
        let y3 = 1 + y + y * y
        let mT = T(m)
        a = a * (1 + y).sqr().sqr() - mT * y * y3
        
        pold = p
        p = 1 / a
//        print("Iteration \(i) : \(p)")
        if p == pold { break }
    }
    
    return p
}

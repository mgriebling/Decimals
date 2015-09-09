//
//  GenericMath.swift
//  Decimals
//
//  Created by Mike Griebling on 8 Sep 2015.
//  Copyright © 2015 Computer Inspirations. All rights reserved.
//

import Foundation

protocol RealOperations : Equatable, IntegerLiteralConvertible {
    func sqrt() -> Self
    func + (_: Self, _: Self) -> Self
    func - (_: Self, _: Self) -> Self
    func * (_: Self, _: Self) -> Self
    func / (_: Self, _: Self) -> Self
    func sqr () -> Self
    init(_ int : Int)
}

public final class MyDecimal {
    
    var n: NSDecimalNumber
    
    init(_ n: NSDecimalNumber) { self.n = n }
    
    public convenience required init(integerLiteral value: Int) { self.init(NSDecimalNumber(integer: value)) }
    
}

extension MyDecimal : RealOperations {
    
    public convenience init (_ int: Int) { self.init(NSDecimalNumber(integer: int)) }
    public func sqr() -> MyDecimal { return MyDecimal(n.decimalNumberByMultiplyingBy(n)) }
    public func sqrt() -> MyDecimal { return self }

}

public func == (lhs: MyDecimal, rhs: MyDecimal) -> Bool {
    return lhs.n.compare(rhs.n) == .OrderedSame
}

public func * (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.decimalNumberByMultiplyingBy(rhs.n))
}

public func / (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.decimalNumberByDividingBy(rhs.n))
}

public func + (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.decimalNumberByAdding(rhs.n))
}

public func - (lhs: MyDecimal, rhs: MyDecimal) -> MyDecimal {
    return MyDecimal(lhs.n.decimalNumberBySubtracting(rhs.n))
}

//
// A generic algorithm to calculate a square root to any precision.
//

func squareRoot (a: Decimal) -> Decimal {
    if a == 0 { return a }
    
    if a.isNegative {
        print("sqrt: Negative argument.")
        return 0
    }
    
    let half = Decimal(1) / 2
    var r = 1 / a
    let h = a * half
    
    let max_iter = 20
    var rold = r
    for i in 1...max_iter {
        rold = r
        r += (half - h * r.sqr()) * r
        print("Iteration \(i) : \(r*a)")
        if (r - rold).abs() < 2*r.eps { break }
    }
    
    r *= a
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
    print("Iteration  0: \(p)")
    
    for i in 1...max_iter {
        m *= 4
        r = (1 - y.sqr().sqr()).sqrt().sqrt()
        y = (1 - r) / (1 + r)
        let y3 = 1 + y + y * y
        let mT = T(m)
        a = a * (1 + y).sqr().sqr() - mT * y * y3
        
        pold = p
        p = 1 / a
        print("Iteration \(i) : \(p)")
        if p == pold { break }
    }
    
    return p
}
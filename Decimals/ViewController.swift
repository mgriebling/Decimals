//
//  ViewController.swift
//  Decimals
//
//  Created by Michael Griebling on 8Sep2015.
//  Copyright © 2015 Solinst Canada. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // addition example -- default digits = 34
        print("Testing library " + Decimal.decNumberVersionString)
        let a = Decimal("1.23456")
        let b = Decimal("10.9876")
        print("\(a) + \(b) = \(a + b)")
        
        // compound interest example
        let years = 20
        let interest = Decimal("6.5") // %
        let start = Decimal(100_000)
        var rate : Decimal
        if !Decimal.errorString.isEmpty {
            print("Illegal input variables")
        }
        rate = interest / 100 + 1   // rate = rate/100 + 1
        rate = rate ** years        // rate = rate ** years
        let error = Decimal.errorString
        if error.isEmpty {
            print("$\(start) at \(interest)% for \(years) years => $\((rate * start).round(-2))")
        } else {
            print("Error: \(error)!!")
        }
        print("Rounding mode = \(Decimal.roundMethod)")
        
        let digits = Decimal.digits
        Decimal.digits = digits+1
        let sqrt2 = Decimal(2).sqrt()   // calculate to one more digit than needed
        Decimal.digits = digits
        print("sqrt(2)   = \(sqrt2)\nsqrt(2)^2 = \(sqrt2 * sqrt2)")
        
        Decimal.digits = 32  // limit logical numbers to 32 bits
        if interest.isLogical { print("\(interest) is logical") }
        else { print("\(interest) is not logical") }
        if start.isLogical { print("\(start) is logical") }
        else { print("\(interest) is not logical") }
        print("10 or 1 = \(Decimal(10) | 1)")
        print("not 1 = \(~Decimal(1))")
        print("1 << 20 = \(Decimal(1) << 20)")
        
        // try encoding/decoding several numbers
        let dataStore = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: dataStore)
        start.encodeWithCoder(archiver)
        rate.encodeWithCoder(archiver)
        archiver.finishEncoding()
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: dataStore as Data)
        let start2 = Decimal(coder: unarchiver)
        let rate2 = Decimal(coder: unarchiver)
        if start == start2 && rate == rate2 { print("Encoding/decoding success!") }
        else { print("Encoding/decoding failure!") }
        
        // compute pi
        Decimal.digits = Decimal.maximumDigits
        let pi : Decimal = computePi()
//        let pi2 : Double = computePi()
        print("Decimal pi = \(pi)")
//        print("Double  pi = \(pi2)")
//        print("Math    pi = \(M_PI)")
        
        // compute sqrt
        let sqrt2a : MyDecimal = squareRoot(2)
        print("sqrt(2) = \(Decimal(2).sqrt())")
        print("sqrt(2) = \(sqrt2a)")
        
        // compute pi
        let pi2 : MyDecimal = computePi()
        print("NSDecimal pi = \(pi2)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


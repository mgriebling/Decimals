# DecNumber
A Swift-friendly interface to the C-based decNumber library.  This package works with either iOS or OSX.
It introduces an arbitrary-precision decimal number and three IEEE 754 decimal-encoded compressed decimal Swift data types: 

1. HDecimal, an arbitrary-precision _huge_ decimal number based on the decNumber library, but with added swift-numerics Real protocol compliance.
2. Decimal32, a 7-digit, 32-bit (4-byte) decimal number based on the decNumber library, but with added swift-numerics Real protocol compliance.
3. Decimal64, a 16-digit, 64-bit (8-byte) decimal number based on the decNumber library, but with added swift-numerics Real protocol compliance.
4. Decimal128, a 34-digit, 128-bit (16-byte) decimal number based on the decNumber library, but with added _swift-numerics_ Real protocol compliance.

All bit-limited data types (i.e., Decimal32, Decimal64, and Decimal128) use operations that only require 32-bit integers, or 64-bits if available
on the native architecture.  Scientific functions currently require the Double data type.

Here's an simple example that creates two floating point decimal numbers, adds them together, and prints the result along with pi and 2**156:

```swift
   let number: HDecimal = "12345678901234567890.12345678901234567890"
   let number2 = HDecimal(5432109)
   print("\(number)+\(number2) =", number+number2)
   print("π =", HDecimal.pi)
   HDecimal.digits = 128
   print("2¹⁵⁶ =", HDecimal(2).pow(HDecimal(156)))
```
        
Resulting in:

```
    12345678901234567890.12345678901234567890+5432109 = 12345678901239999999.123456789012345679
    π = 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446
    2¹⁵⁶ = 91343852333181432387730302044767688728495783936
```
        
## More Examples
Here are the examples, included with the decNumber library, translated to Swift:

### Example 1
The first example shows how to create and add two HDecimal numbers.
Note: There is no need to do an endian check since this is done by the context initializer.
In fact, even the context is automatically initialized by the `HDecimal` class.  

```swift
import ArgumentParser
import Decimals

struct Example1 : ParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName:   "example1",
        abstract:      "Demonstrates adding two HDecimal numbers",
        shouldDisplay: true
    )
    
    @Argument(help: "First number to be added")
    var number1 : String
    
    @Argument(help: "Second number to be added")
    var number2 : String
    
    mutating func run() throws {
        HDecimal.digits = HDecimal.maximumDigits
        let a = HDecimal(number1)!, b = HDecimal(number2)!
        print("\(a) + \(b) => \(a+b)")
    }
}

Example1.main()
```

This code above, which includes an argument parser, gives the following output with this input `example1 1234567890.123456789 8765432109.876543210`:

```
1234567890.123456789 + 8765432109.876543211 => 10000000000.000000000
Program ended with exit code: 0
```

### Example 2
The second example calculates compound interest on an initial `investment` at `rate`% for `years` years. 

```swift
   HDecimal.digits = 25
   
   let investment = HDecimal(investment)!
   var irate = HDecimal(rate)! / 100 + 1
   let years = HDecimal(years)!
   
   irate = irate ** years          // rate for years
   let total = irate * investment  // total investment with interest
   let total2 = total.rescale(-2)  // round to two digits
   print("Invest $\(investment) at \(rate)% for \(years) years => $\(total2)")  
```

gives the following output:

```
Invest $100000 at 10% for 25 years => $1083470.59
Program ended with exit code: 0
```


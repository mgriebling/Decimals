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

        let number: HDecimal = "12345678901234567890.12345678901234567890"
        let number2 = HDecimal(5432109)
        print("\(number)+\(number2) =", number+number2)
        print("π =", HDecimal.pi)
        HDecimal.digits = 128
        print("2¹⁵⁶ =", HDecimal(2).pow(HDecimal(156)))
        
Resulting in:

        12345678901234567890.12345678901234567890+5432109 = 12345678901239999999.123456789012345679
        π = 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446
        2¹⁵⁶ = 91343852333181432387730302044767688728495783936

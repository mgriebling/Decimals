# DecNumber
A Swift-friendly interface to the C-based decNumber library.  This package works with either iOS or OSX.
It introduces two arbitrary-precision decimal numbers and six IEEE 754 decimal-encoded compressed decimal Swift data types: 

1. HDecimal, an arbitrary-precision _huge_ decimal number based on the decNumber library, but with added swift-numerics Real protocol compliance.
2. CDecimal, a complex number data type built on the HDecimal decimal number type using the _swift-numerics_ Complex generic definition.
3. Decimal32, a 7-digit, 32-bit (4-byte) decimal number based on the decNumber library, but with added swift-numerics Real protocol compliance.
4. CDecimal32, a complex number data type built on the Decimal32 decimal number type using the _swift-numerics_ Complex generic definition.
5. Decimal64, a 16-digit, 64-bit (8-byte) decimal number based on the decNumber library, but with added swift-numerics Real protocol compliance.
6. CDecimal64, a complex number data type built on the Decimal64 decimal number type using the _swift-numerics_ Complex generic definition.
7. Decimal128, a 34-digit, 128-bit (16-byte) decimal number based on the decNumber library, but with added _swift-numerics_ Real protocol compliance.
8. CDecimal128, a complex number data type built on the Decimal128 decimal number type using the _swift-numerics_ Complex generic definition.

All bit-limited data types (i.e., Decimal32, Decimal64, and Decimal128) use operations that only require 32-bit integers, or 64-bits if available
on the native architecture.  Scientific functions currently require the Double data type.

Here's an simple example that creates a large floating point decimal number and prints it out:
        ```
        let number: HDecimal = "12345678901234567890.12345678901234567890"
        let number2 = HDecimal(5432109)
        print(number+number2)
        ```
        
Resulting in:
        ```12345678901239999999.123456789012345679```

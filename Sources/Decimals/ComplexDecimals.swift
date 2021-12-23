//
//  ComplexDecimals.swift
//  DecNumber
//
//  Created by Mike Griebling on 2021-12-17.
//  Copyright © 2021 Computer Inspirations. All rights reserved.
//

import Foundation
import Numerics

/// Complex datatype based on the HDecimal type
/// Note: This works because HDecimal is Real-compliant
typealias CDecimal = Complex<HDecimal>

/// Complex datatype based on the Decimal32 type
typealias CDecimal32 = Complex<Decimal32>

/// Complex datatype based on the Decimal32 type
typealias CDecimal64 = Complex<Decimal64>

/// Complex datatype based on the Decimal32 type
typealias CDecimal128 = Complex<Decimal128>


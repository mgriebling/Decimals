//
//  DecContext.swift
//  DecNumber
//
//  Created by Mike Griebling on 2021-12-16.
//  Copyright © 2021 Computer Inspirations. All rights reserved.
//

import Foundation
import CDecNumber

public struct DecContext {
    
    public enum RoundingType: Codable, CaseIterable {
        case ceiling    /* round towards +infinity         */
        case up         /* round away from 0               */
        case halfUp     /* 0.5 rounds up                   */
        case halfEven   /* 0.5 rounds to nearest even      */
        case halfDown   /* 0.5 rounds down                 */
        case down       /* round towards 0 (truncate)      */
        case floor      /* round towards -infinity         */
        case r05Up      /* round for reround               */
        case max        /* enum must be less than this     */
        
        var value: rounding {
            switch self {
                case .ceiling:  return DEC_ROUND_CEILING
                case .up:       return DEC_ROUND_UP
                case .halfUp:   return DEC_ROUND_HALF_UP
                case .halfEven: return DEC_ROUND_HALF_EVEN
                case .halfDown: return DEC_ROUND_HALF_DOWN
                case .down:     return DEC_ROUND_DOWN
                case .floor:    return DEC_ROUND_FLOOR
                case .r05Up:    return DEC_ROUND_05UP
                case .max:      return DEC_ROUND_MAX
            }
        }
        
        fileprivate init(_ value: rounding) {
            // reverse mapping from rounding type to RoundingType
            self = RoundingType.allCases.filter { $0.value.rawValue == value.rawValue }.first ?? .halfEven
        }
    }
    
    public enum ContextInitType: Codable {
        case base       // ANSI X3.274 arithmetic subset: digits = 9, emax = 999999999, round = halfUp, status = 0, all traps
        case dec32      // IEEE 754 rules: digits = 7, emax = 96, emin = -95, round = halfEven, status = 0, no traps
        case dec64      // IEEE 754 rules: digits = 16, emax = 384, emin = -383, round = halfEven, status = 0, no traps
        case dec128     // IEEE 754 rules: digits = 34, emax = 6144, emin = -6143, round = halfEven, status = 0, no traps
        
        fileprivate var value: Int32 {
            switch self {
                case .base:   return DEC_INIT_BASE
                case .dec32:  return DEC_INIT_DECIMAL32
                case .dec64:  return DEC_INIT_DECIMAL64
                case .dec128: return DEC_INIT_DECIMAL128
            }
        }
    }
 
    public struct Status: OptionSet, CustomStringConvertible {
        
        public var description: String {
            var context = decContext()
            decContextSetStatusQuiet(&context, UInt32(rawValue))
            let str = decContextStatusToString(&context)!
            return String(cString: str)
        }
        
        public let rawValue: Int32
        
        public static let conversionSyntax    = Status(rawValue: DEC_Conversion_syntax)
        public static let divisionByZero      = Status(rawValue: DEC_Division_by_zero)
        public static let divisionImpossible  = Status(rawValue: DEC_Division_impossible)
        public static let divisionUndefined   = Status(rawValue: DEC_Division_undefined)
        public static let insufficientStorage = Status(rawValue: DEC_Insufficient_storage)
        public static let inexact             = Status(rawValue: DEC_Inexact)
        public static let invalidContext      = Status(rawValue: DEC_Invalid_context)
        public static let invalidOperation    = Status(rawValue: DEC_Invalid_operation)
        public static let overflow            = Status(rawValue: DEC_Overflow)
        public static let clamped             = Status(rawValue: DEC_Clamped)
        public static let rounded             = Status(rawValue: DEC_Rounded)
        public static let subnormal           = Status(rawValue: DEC_Subnormal)
        public static let underflow           = Status(rawValue: DEC_Underflow)
        public static let clearFlags          = Status([])
        
        public static let errorFlags = Status(rawValue: DEC_IEEE_754_Division_by_zero | DEC_IEEE_754_Overflow |
            DEC_IEEE_754_Underflow | DEC_Conversion_syntax | DEC_Division_impossible |
            DEC_Division_undefined | DEC_Insufficient_storage | DEC_Invalid_context | DEC_Invalid_operation)
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    var base = decContext()
    let initKind: ContextInitType
    
    private mutating func setRounding(_ round: rounding) { decContextSetRounding(&base, round) }
    private func getRounding() -> rounding { var context = base; return decContextGetRounding(&context) }
    
    // access to states
    public var roundMode: RoundingType {
        get { RoundingType(getRounding()) }
        set { setRounding(newValue.value) }
    }
    
    public var status: Status {
        get { Status(rawValue: Int32(base.status)) }
        set {
            if newValue == .clearFlags { decContextZeroStatus(&base) }
            else { decContextSetStatusQuiet(&base, UInt32(newValue.rawValue)) }
        }
    }
    
    public var digits: Int {
        get { Int(base.digits) }
        set {
            if initKind == .base && newValue > 0 && newValue <= DECNUMDIGITS {
                base.digits = Int32(newValue)
            }
        }
    }
    
    init(initKind: ContextInitType) {
        assert(decContextTestEndian(1) == 0, "Error: Endian flag \"DECLITEND\" is incorrectly set")
        self.initKind = initKind
        decContextDefault(&base, initKind.value)
        
    }
    
}

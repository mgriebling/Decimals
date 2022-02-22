import XCTest
@testable import Decimals

final class DecimalsTests: XCTestCase {

//    func testMiscellaneous() {
//        // Test Decimal to int conversions
//        let n = -1234567890123456789
//        XCTAssertEqual(n, Decimal128(n).int)
//
//        XCTAssertEqual(HDecimal.greatestFiniteMagnitude.description, "9.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999E+999999999")
//        XCTAssertEqual(HDecimal.leastNonzeroMagnitude.description,   "1E-1000000126")
//        XCTAssertEqual(HDecimal.leastNormalMagnitude.description,    "9.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999E-999999999")
//
//        /// Test basic functions
//        let sqrt2     = "1.4142135623730950488016887242096980785696718753769480731766797379907324784621070388503875343276415727350138462309122970249248361"
//        let sqrt2_32  = "1.414214"
//        let sqrt2_64  = "1.414213562373095"
//        let sqrt2_128 = "1.414213562373095048801688724209698"
//        XCTAssertEqual(HDecimal.two.squareRoot().description,   sqrt2)
//        XCTAssertEqual(Decimal32.two.squareRoot().description,  sqrt2_32)
//        XCTAssertEqual(Decimal64.two.squareRoot().description,  sqrt2_64)
//        XCTAssertEqual(Decimal128.two.squareRoot().description, sqrt2_128)
//
//        XCTAssertEqual(HDecimal.factorial(69).description,   "171122452428141311372468338881272839092270544893520369393648040923257279754140647424000000000000000")
//        XCTAssertEqual(Decimal32.factorial(69).description,  "Infinity")  // Exceeds maximum exponent
//        XCTAssertEqual(Decimal64.factorial(69).description,  "1.711224524281413E+98")
//        XCTAssertEqual(Decimal128.factorial(69).description, "1.711224524281413113724683388812727E+98")
//
//        XCTAssertEqual(HDecimal.exp(1).description,   "2.7182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274274663919320030599218174136")
//        XCTAssertEqual(Decimal32.exp(1).description,  "2.718282")
//        XCTAssertEqual(Decimal64.exp(1).description,  "2.718281828459045")
//        XCTAssertEqual(Decimal128.exp(1).description, "2.718281828459045235360287471352662")
//
//        HDecimal.digits = HDecimal.maximumDigits
//        let half = HDecimal.one/2
//        XCTAssertEqual(HDecimal.pow(2, half).description,    sqrt2)
//        XCTAssertEqual(Decimal32.pow(2, 1.0/2).description,  sqrt2_32)
//        XCTAssertEqual(Decimal64.pow(2, 1.0/2).description,  sqrt2_64)
//        XCTAssertEqual(Decimal128.pow(2, 1.0/2).description, sqrt2_128)
//
//        XCTAssertEqual(HDecimal.sin(1).description,   "0.84147098480789650665250232163029899962256306079837106567275170999191040439123966894863974354305269585434903790792067429325911893")
//        XCTAssertEqual(Decimal32.sin(1).description,  "0.8414710")
//        XCTAssertEqual(Decimal64.sin(1).description,  "0.8414709848078965")
//        XCTAssertEqual(Decimal128.sin(1).description, "0.8414709848078965066525023216302990")
//
//        XCTAssertEqual(HDecimal.cos(1).description,   "0.54030230586813971740093660744297660373231042061792222767009725538110039477447176451795185608718308934357173116003008909786063378")
//        XCTAssertEqual(Decimal32.cos(1).description,  "0.5403023")
//        XCTAssertEqual(Decimal64.cos(1).description,  "0.5403023058681398")
//        XCTAssertEqual(Decimal128.cos(1).description, "0.5403023058681397174009366074429766")
//
//        XCTAssertEqual(HDecimal.tan(1).description,   "1.5574077246549022305069748074583601730872507723815200383839466056988613971517272895550999652022429838046338214117481666133235546")
//        XCTAssertEqual(Decimal32.tan(1).description,  "1.557408")
//        XCTAssertEqual(Decimal64.tan(1).description,  "1.557407724654902")
//        XCTAssertEqual(Decimal128.tan(1).description, "1.557407724654902230506974807458360")
//
//        XCTAssertEqual(HDecimal.asin(1).description,   "1.5707963267948966192313216916397514420985846996875529104874722961539082031431044993140174126710585339910740432566411533235469223")
//        XCTAssertEqual(Decimal32.asin(1).description,  "1.570796")
//        XCTAssertEqual(Decimal64.asin(1).description,  "1.570796326794897")
//        XCTAssertEqual(Decimal128.asin(1).description, "1.570796326794896619231321691639751")
//
//        XCTAssertEqual(HDecimal.acos(half).description,    "1.0471975511965977461542144610931676280657231331250352736583148641026054687620696662093449417807056893273826955044274355490312816")
//        XCTAssertEqual(Decimal32.acos(1.0/2).description,  "1.047198")
//        XCTAssertEqual(Decimal64.acos(1.0/2).description,  "1.047197551196598")
//        XCTAssertEqual(Decimal128.acos(1.0/2).description, "1.047197551196597746154214461093168")
//
//        XCTAssertEqual(HDecimal.atan(1).description,   "0.78539816339744830961566084581987572104929234984377645524373614807695410157155224965700870633552926699553702162832057666177346115")
//        XCTAssertEqual(Decimal32.atan(1).description,  "0.7853982")
//        XCTAssertEqual(Decimal64.atan(1).description,  "0.7853981633974483")
//        XCTAssertEqual(Decimal128.atan(1).description, "0.7853981633974483096156608458198757")
//
//        XCTAssertEqual(HDecimal.sinh(1).description,   "1.1752011936438014568823818505956008151557179813340958702295654130133075673043238956071174520896233918404195333275795323567852189")
//        XCTAssertEqual(Decimal32.sinh(1).description,  "1.175201")
//        XCTAssertEqual(Decimal64.sinh(1).description,  "1.175201193643801")
//        XCTAssertEqual(Decimal128.sinh(1).description, "1.175201193643801456882381850595601")
//
//        XCTAssertEqual(HDecimal.cosh(1).description,   "1.5430806348152437784779056207570616826015291123658637047374022147107690630492236989642647264355430355870468586044235275650321947")
//        XCTAssertEqual(Decimal32.cosh(1).description,  "1.543081")
//        XCTAssertEqual(Decimal64.cosh(1).description,  "1.543080634815244")
//        XCTAssertEqual(Decimal128.cosh(1).description, "1.543080634815243778477905620757062")
//
//
//        XCTAssertEqual(HDecimal.tanh(1).description,   "0.76159415595576488811945828260479359041276859725793655159681050012195324457663848345894752167367671442190275970155407753236830911")
//        XCTAssertEqual(Decimal32.tanh(1).description,  "0.7615942")
//        XCTAssertEqual(Decimal64.tanh(1).description,  "0.7615941559557649")
//        XCTAssertEqual(Decimal128.tanh(1).description, "0.7615941559557648881194582826047936")
//
//        XCTAssertEqual(HDecimal.asinh(1).description,   "0.88137358701954302523260932497979230902816032826163541075329560865337718422202608783370689191025604285673981619210649218876207253")
//        XCTAssertEqual(Decimal32.asinh(1).description,  "0.8813736")
//        XCTAssertEqual(Decimal64.asinh(1).description,  "0.8813735870195430")
//        XCTAssertEqual(Decimal128.asinh(1).description, "0.8813735870195430252326093249797923")
//
//       //  print(Double.atanh(0.5), HDecimal.atanh(half), Decimal32.atanh(0.5), Decimal64.atanh(0.5), Decimal128.atanh(0.5))
//        XCTAssertEqual(HDecimal.acosh(2).description,   "1.3169578969248167086250463473079684440269819714675164797684722569204601854164439760742190134501017835564654365656049793198098169")
//        XCTAssertEqual(Decimal32.acosh(2).description,  "1.316958")
//        XCTAssertEqual(Decimal64.acosh(2).description,  "1.316957896924817")
//        XCTAssertEqual(Decimal128.acosh(2).description, "1.316957896924816708625046347307968")
//
//        XCTAssertEqual(HDecimal.atanh(half).description,  "0.5493061443340548456976226184612628523237452789113747258673471668187471466093044834368078774068660443939850145329789328711840021")
//        XCTAssertEqual(Decimal32.atanh(0.5).description,  "0.5493061")
//        XCTAssertEqual(Decimal64.atanh(0.5).description,  "0.5493061443340549")
//        XCTAssertEqual(Decimal128.atanh(0.5).description, "0.5493061443340548456976226184612629")
//
//        XCTAssertEqual(HDecimal.log2(10).description,   "3.3219280948873623478703194294893901758648313930245806120547563958159347766086252158501397433593701550996573717102502518268240970")
//        XCTAssertEqual(Decimal32.log2(10).description,  "3.321928")
//        XCTAssertEqual(Decimal64.log2(10).description,  "3.321928094887362")
//        XCTAssertEqual(Decimal128.log2(10).description, "3.321928094887362347870319429489390")
//
//        XCTAssertEqual(HDecimal.log10(2).description,   "0.30102999566398119521373889472449302676818988146210854131042746112710818927442450948692725211818617204068447719143099537909476788")
//        XCTAssertEqual(Decimal32.log10(2).description,  "0.3010300")
//        XCTAssertEqual(Decimal64.log10(2).description,  "0.3010299956639812")
//        XCTAssertEqual(Decimal128.log10(2).description, "0.3010299956639811952137388947244930")
//
//        XCTAssertEqual(HDecimal.log(10).description,   "2.3025850929940456840179914546843642076011014886287729760333279009675726096773524802359972050895982983419677840422862486334095255")
//        XCTAssertEqual(Decimal32.log(10).description,  "2.302585")
//        XCTAssertEqual(Decimal64.log(10).description,  "2.302585092994046")
//        XCTAssertEqual(Decimal128.log(10).description, "2.302585092994045684017991454684364")
//
//        XCTAssertEqual(HDecimal.pi.description,   "3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446")
//        XCTAssertEqual(Decimal32.pi.description,  "3.141593")
//        XCTAssertEqual(Decimal64.pi.description,  "3.141592653589793")
//        XCTAssertEqual(Decimal128.pi.description, "3.141592653589793238462643383279503")
//
//        let a = HDecimal.random(in: 0..<1)
//        XCTAssert(a >= 0 && a < 1)
//        print("HDecimal.random(0..<1) = \(a)")
//    }
//
//    func testEncodingDecimal128() {
//        // Test encoding for Decimal64 strings and integers
//        var testNumber = 0
//
//        func test(_ value: String, result: String) {
//            testNumber += 1
//            if let n = Decimal128(value) {
//                print("Test \(testNumber): \"\(value)\" [\(n)] = \(result.uppercased()) - \(n.numberClass.description)")
//                XCTAssertEqual(n.debugDescription, result.uppercased())
//            } else {
//                XCTAssert(false, "Failed to convert '\(value)'")
//            }
//        }
//
//        func test(_ value: Int, result : String) {
//            testNumber += 1
//            let n = Decimal128(value)
//            print("Test \(testNumber): \(value) [\(n)] = \(result.uppercased()) - \(n.numberClass.description)")
//            XCTAssertEqual(n.debugDescription, result.uppercased())
//        }
//
//        /// Check min/max values
//        XCTAssertEqual(Decimal128.greatestFiniteMagnitude.description, "9.999999999999999999999999999999999E+6144")
//        XCTAssertEqual(Decimal128.leastNonzeroMagnitude.description,   "1E-6176")
//        XCTAssertEqual(Decimal128.leastNormalMagnitude.description,    "9.999999999999999999999999999999999E-6143")
//
//        /// Verify various string and integer encodings
//        // General testcases
//        // (mostly derived from the Strawman 4 document and examples)
//        test("-7.50",       result: "A20780000000000000000000000003D0")
//        // derivative canonical plain strings
//        test("-7.50E+3",    result: "A20840000000000000000000000003D0")
//        test(-750,          result: "A20800000000000000000000000003D0")
//        test("-75.0",       result: "A207c0000000000000000000000003D0")
//        test("-0.750",      result: "A20740000000000000000000000003D0")
//        test("-0.0750",     result: "A20700000000000000000000000003D0")
//        test("-0.000750",   result: "A20680000000000000000000000003D0")
//        test("-0.00000750", result: "A20600000000000000000000000003D0")
//        test("-7.50E-7",    result: "A205c0000000000000000000000003D0")
//
//        // Normality
//        test("1234567890123456789012345678901234",  result: "2608134b9c1e28e56f3c127177823534")
//        test("-1234567890123456789012345678901234", result: "a608134b9c1e28e56f3c127177823534")
//        test("1111111111111111111111111111111111",  result: "26080912449124491244912449124491")
//
//        // Nmax and similar
//        test("9.999999999999999999999999999999999E+6144", result: "77ffcff3fcff3fcff3fcff3fcff3fcff")
//        test("1.234567890123456789012345678901234E+6144", result: "47ffd34b9c1e28e56f3c127177823534")
//        // fold-downs (more below)
//        test("1.23E+6144", result: "47ffd300000000000000000000000000")
//        test("1E+6144",    result: "47ffc000000000000000000000000000")
//
//        test(12345,    result: "220800000000000000000000000049c5")
//        test(1234,     result: "22080000000000000000000000000534")
//        test(123,      result: "220800000000000000000000000000a3")
//        test(12,       result: "22080000000000000000000000000012")
//        test(1,        result: "22080000000000000000000000000001")
//        test("1.23",   result: "220780000000000000000000000000a3")
//        test("123.45", result: "220780000000000000000000000049c5")
//
//        // Nmin and below
//        test("1E-6143", result: "00084000000000000000000000000001")
//        test("1.000000000000000000000000000000000E-6143", result: "04000000000000000000000000000000")
//        test("1.000000000000000000000000000000001E-6143", result: "04000000000000000000000000000001")
//        test("0.100000000000000000000000000000000E-6143", result: "00000800000000000000000000000000")
//        test("0.000000000000000000000000000000010E-6143", result: "00000000000000000000000000000010")
//        test("0.00000000000000000000000000000001E-6143",  result: "00004000000000000000000000000001")
//        test("0.000000000000000000000000000000001E-6143", result: "00000000000000000000000000000001")
//
//        // underflows cannot be tested for simple copies, check edge cases
//        test("1e-6176", result: "00000000000000000000000000000001")
//        test("999999999999999999999999999999999e-6176", result: "00000ff3fcff3fcff3fcff3fcff3fcff")
//
//        // same again, negatives
//        // Nmax and similar
//        test("-9.999999999999999999999999999999999E+6144", result: "f7ffcff3fcff3fcff3fcff3fcff3fcff")
//        test("-1.234567890123456789012345678901234E+6144", result: "c7ffd34b9c1e28e56f3c127177823534")
//        // fold-downs (more below)
//        test("-1.23E+6144", result: "c7ffd300000000000000000000000000")
//        test("-1E+6144",    result: "c7ffc000000000000000000000000000")
//
//        test(-12345,        result: "a20800000000000000000000000049c5")
//        test(-1234,         result: "a2080000000000000000000000000534")
//        test(-123,          result: "a20800000000000000000000000000a3")
//        test(-12,           result: "a2080000000000000000000000000012")
//        test(-1,            result: "a2080000000000000000000000000001")
//        test("-1.23",       result: "a20780000000000000000000000000a3")
//        test("-123.45",     result: "a20780000000000000000000000049c5")
//
//        // Nmin and below
//        test("-1E-6143", result: "80084000000000000000000000000001")
//        test("-1.000000000000000000000000000000000E-6143", result: "84000000000000000000000000000000")
//        test("-1.000000000000000000000000000000001E-6143", result: "84000000000000000000000000000001")
//
//        test("-0.100000000000000000000000000000000E-6143", result: "80000800000000000000000000000000")
//        test("-0.000000000000000000000000000000010E-6143", result: "80000000000000000000000000000010")
//        test("-0.00000000000000000000000000000001E-6143",  result: "80004000000000000000000000000001")
//        test("-0.000000000000000000000000000000001E-6143", result: "80000000000000000000000000000001")
//
//        // underflow edge cases
//        test("-1e-6176", result: "80000000000000000000000000000001")
//        test("-999999999999999999999999999999999e-6176", result: "80000ff3fcff3fcff3fcff3fcff3fcff")
//        // zeros
//        test("0E-8000", result: "00000000000000000000000000000000")
//        test("0E-6177", result: "00000000000000000000000000000000")
//        test("0E-6176", result: "00000000000000000000000000000000")
//        test("0.000000000000000000000000000000000E-6143", result: "00000000000000000000000000000000")
//        test("0E-2",    result: "22078000000000000000000000000000")
//        test("0",       result: "22080000000000000000000000000000")
//        test("0E+3",    result: "2208c000000000000000000000000000")
//        test("0E+6111", result: "43ffc000000000000000000000000000")
//        // clamped zeros...
//        test("0E+6112", result: "43ffc000000000000000000000000000")
//        test("0E+6144", result: "43ffc000000000000000000000000000")
//        test("0E+8000", result: "43ffc000000000000000000000000000")
//        // negative zeros
//        test("-0E-8000", result: "80000000000000000000000000000000")
//        test("-0E-6177", result: "80000000000000000000000000000000")
//        test("-0E-6176", result: "80000000000000000000000000000000")
//        test("-0.000000000000000000000000000000000E-6143", result: "80000000000000000000000000000000")
//        test("-0E-2",    result: "a2078000000000000000000000000000")
//        test("-0",       result: "a2080000000000000000000000000000")
//        test("-0E+3",    result: "a208c000000000000000000000000000")
//        test("-0E+6111", result: "c3ffc000000000000000000000000000")
//        // clamped zeros...
//        test("-0E+6112", result: "c3ffc000000000000000000000000000")
//        test("-0E+6144", result: "c3ffc000000000000000000000000000")
//        test("-0E+8000", result: "c3ffc000000000000000000000000000")
//
//        // exponent lengths
//        test("7",        result: "22080000000000000000000000000007")
//        test("7E+9",     result: "220a4000000000000000000000000007")
//        test("7E+99",    result: "2220c000000000000000000000000007")
//        test("7E+999",   result: "2301c000000000000000000000000007")
//        test("7E+5999",  result: "43e3c000000000000000000000000007")
//
//        // Specials
//        test("Infinity",  result: "78000000000000000000000000000000")
//        test("NaN",       result: "7c000000000000000000000000000000")
//        test("-Infinity", result: "f8000000000000000000000000000000")
//        test("-NaN",      result: "fc000000000000000000000000000000")
//
//        test("NaN",       result: "7c000000000000000000000000000000")
//        test("NaN0",      result: "7c000000000000000000000000000000")
//        test("NaN1",      result: "7c000000000000000000000000000001")
//        test("NaN12",     result: "7c000000000000000000000000000012")
//        test("NaN79",     result: "7c000000000000000000000000000079")
//        test("NaN12345",  result: "7c0000000000000000000000000049c5")
//        test("NaN123456", result: "7c000000000000000000000000028e56")
//        test("NaN799799", result: "7c0000000000000000000000000f7fdf")
//        test("NaN799799799799799799799799799799799", result: "7c003dff7fdff7fdff7fdff7fdff7fdf")
//        test("NaN999999999999999999999999999999999", result: "7c000ff3fcff3fcff3fcff3fcff3fcff")
//        test("9999999999999999999999999999999999",   result: "6e080ff3fcff3fcff3fcff3fcff3fcff")
//
//        // fold-down full sequence
//        test("1E+6144", result: "47ffc000000000000000000000000000")
//        test("1E+6143", result: "43ffc800000000000000000000000000")
//        test("1E+6142", result: "43ffc100000000000000000000000000")
//        test("1E+6141", result: "43ffc010000000000000000000000000")
//        test("1E+6140", result: "43ffc002000000000000000000000000")
//        test("1E+6139", result: "43ffc000400000000000000000000000")
//        test("1E+6138", result: "43ffc000040000000000000000000000")
//        test("1E+6137", result: "43ffc000008000000000000000000000")
//        test("1E+6136", result: "43ffc000001000000000000000000000")
//        test("1E+6135", result: "43ffc000000100000000000000000000")
//        test("1E+6134", result: "43ffc000000020000000000000000000")
//        test("1E+6133", result: "43ffc000000004000000000000000000")
//        test("1E+6132", result: "43ffc000000000400000000000000000")
//        test("1E+6131", result: "43ffc000000000080000000000000000")
//        test("1E+6130", result: "43ffc000000000010000000000000000")
//        test("1E+6129", result: "43ffc000000000001000000000000000")
//        test("1E+6128", result: "43ffc000000000000200000000000000")
//        test("1E+6127", result: "43ffc000000000000040000000000000")
//        test("1E+6126", result: "43ffc000000000000004000000000000")
//        test("1E+6125", result: "43ffc000000000000000800000000000")
//        test("1E+6124", result: "43ffc000000000000000100000000000")
//        test("1E+6123", result: "43ffc000000000000000010000000000")
//        test("1E+6122", result: "43ffc000000000000000002000000000")
//        test("1E+6121", result: "43ffc000000000000000000400000000")
//        test("1E+6120", result: "43ffc000000000000000000040000000")
//        test("1E+6119", result: "43ffc000000000000000000008000000")
//        test("1E+6118", result: "43ffc000000000000000000001000000")
//        test("1E+6117", result: "43ffc000000000000000000000100000")
//        test("1E+6116", result: "43ffc000000000000000000000020000")
//        test("1E+6115", result: "43ffc000000000000000000000004000")
//        test("1E+6114", result: "43ffc000000000000000000000000400")
//        test("1E+6113", result: "43ffc000000000000000000000000080")
//        test("1E+6112", result: "43ffc000000000000000000000000010")
//        test("1E+6111", result: "43ffc000000000000000000000000001")
//        test("1E+6110", result: "43ff8000000000000000000000000001")
//
//        // Miscellaneous (testers' queries, etc.)
//        test(30000,  result: "2208000000000000000000000000c000")
//        test(890000, result: "22080000000000000000000000007800")
//
//        // d [u]int32 edges (zeros done earlier)
//        test(-2147483646, result: "a208000000000000000000008c78af46")
//        test(-2147483647, result: "a208000000000000000000008c78af47")
//        test(-2147483648, result: "a208000000000000000000008c78af48")
//        test(-2147483649, result: "a208000000000000000000008c78af49")
//        test(2147483646,  result: "2208000000000000000000008c78af46")
//        test(2147483647,  result: "2208000000000000000000008c78af47")
//        test(2147483648,  result: "2208000000000000000000008c78af48")
//        test(2147483649,  result: "2208000000000000000000008c78af49")
//        test(4294967294,  result: "22080000000000000000000115afb55a")
//        test(4294967295,  result: "22080000000000000000000115afb55b")
//        test(4294967296,  result: "22080000000000000000000115afb57a")
//        test(4294967297,  result: "22080000000000000000000115afb57b")
//    }
//
//    func testEncodingDecimal64() {
//        // Test encoding for Decimal64 strings and integers
//        var testNumber = 0
//
//        func test(_ value: String, result: String) {
//            testNumber += 1
//            if let n = Decimal64(value) {
//                print("Test \(testNumber): \"\(value)\" [\(n)] = \(result.uppercased()) - \(n.numberClass.description)")
//                XCTAssertEqual(n.debugDescription, result.uppercased())
//            } else {
//                XCTAssert(false, "Failed to convert '\(value)'")
//            }
//        }
//
//        func test(_ value: Int, result : String) {
//            testNumber += 1
//            let n = Decimal64(value)
//            print("Test \(testNumber): \(value) [\(n)] = \(result.uppercased()) - \(n.numberClass.description)")
//            XCTAssertEqual(n.debugDescription, result.uppercased())
//        }
//
//        /// Check min/max values
//        XCTAssertEqual(Decimal64.greatestFiniteMagnitude.description, "9.999999999999999E+384")
//        XCTAssertEqual(Decimal64.leastNonzeroMagnitude.description,   "1E-398")
//        XCTAssertEqual(Decimal64.leastNormalMagnitude.description,    "9.999999999999999E-383")
//
//        /// Verify various string and integer encodings
//        test("-7.50",             result: "A2300000000003D0")
//        test("-7.50E+3",          result: "A23c0000000003D0")
//        test("-750",              result: "A2380000000003D0")
//        test("-75.0",             result: "A2340000000003D0")
//        test("-0.750",            result: "A22C0000000003D0")
//        test("-0.0750",           result: "A2280000000003D0")
//        test("-0.000750",         result: "A2200000000003D0")
//        test("-0.00000750",       result: "A2180000000003D0")
//        test("-7.50E-7",          result: "A2140000000003D0")
//
//        // Normality
//        test(1234567890123456,    result: "263934b9c1e28e56")
//        test(-1234567890123456,   result: "a63934b9c1e28e56")
//        test("1234.567890123456", result: "260934b9c1e28e56")
//        test(1111111111111111,    result: "2638912449124491")
//        test(9999999999999999,    result: "6e38ff3fcff3fcff")
//
//        // Nmax and similar
//        test("9999999999999999E+369",  result: "77fcff3fcff3fcff")
//        test("9.999999999999999E+384", result: "77fcff3fcff3fcff")
//        test("1.234567890123456E+384", result: "47fd34b9c1e28e56")
//        // fold-downs (more below)
//        test("1.23E+384",           result: "47fd300000000000") // Clamped
//        test("1E+384",              result: "47fc000000000000") // Clamped
//        test(12345,                 result: "22380000000049c5")
//        test(1234,                  result: "2238000000000534")
//        test(123,                   result: "22380000000000a3")
//        test(12,                    result: "2238000000000012")
//        test(1,                     result: "2238000000000001")
//        test("1.23",                result: "22300000000000a3")
//        test("123.45",              result: "22300000000049c5")
//
//        // Nmin and below
//        test("1E-383"                , result: "003c000000000001")
//        test("1.000000000000000E-383", result: "0400000000000000")
//        test("1.000000000000001E-383", result: "0400000000000001")
//
//        test("0.100000000000000E-383", result: "0000800000000000") //      Subnormal
//        test("0.000000000000010E-383", result: "0000000000000010") //     Subnormal
//        test("0.00000000000001E-383",  result: "0004000000000001") //     Subnormal
//        test("0.000000000000001E-383", result: "0000000000000001") //     Subnormal
//        // next is smallest all-nines
//        test("9999999999999999E-398",  result: "6400ff3fcff3fcff")
//        // and a problematic divide result
//        test("1.111111111111111E-383", result: "0400912449124491")
//
//        // forties
//        test(40,        result: "2238000000000040")
//        test("39.99",   result: "2230000000000cff")
//
//        // underflows cannot be tested as all LHS exact
//
//        // Same again, negatives
//        // Nmax and similar
//        test("-9.999999999999999E+384", result: "f7fcff3fcff3fcff")
//        test("-1.234567890123456E+384", result: "c7fd34b9c1e28e56")
//        // fold-downs (more below)
//        test("-1.23E+384",              result: "c7fd300000000000") // Clamped
//        test("-1E+384",                 result: "c7fc000000000000") // Clamped
//
//        // overflows
//        test(-12345,    result: "a2380000000049c5")
//        test(-1234,     result: "a238000000000534")
//        test(-123,      result: "a2380000000000a3")
//        test(-12,       result: "a238000000000012")
//        test(-1,        result: "a238000000000001")
//        test("-1.23",   result: "a2300000000000a3")
//        test("-123.45", result: "a2300000000049c5")
//
//        // Nmin and below
//        test("-1E-383",                 result: "803c000000000001")
//        test("-1.000000000000000E-383", result: "8400000000000000")
//        test("-1.000000000000001E-383", result: "8400000000000001")
//
//        test("-0.100000000000000E-383", result: "8000800000000000") //        Subnormal
//        test("-0.000000000000010E-383", result: "8000000000000010") //        Subnormal
//        test("-0.00000000000001E-383",  result: "8004000000000001") //        Subnormal
//        test("-0.000000000000001E-383", result: "8000000000000001") //        Subnormal
//        // next is smallest all-nines
//        test("-9999999999999999E-398",  result: "e400ff3fcff3fcff")
//        // and a tricky subnormal
//        test("1.11111111111524E-384",   result: "00009124491246a4") //       Subnormal
//
//        // near-underflows
//        test("-1e-398",   result: "8000000000000001") //   Subnormal
//        test("-1.0e-398", result: "8000000000000001") //   Subnormal Rounded
//
//        // zeros
//        test("0E-500", result: "0000000000000000") //   Clamped
//        test("0E-400", result: "0000000000000000") //   Clamped
//        test("0E-398", result: "0000000000000000")
//        test("0.000000000000000E-383", result: "0000000000000000")
//        test("0E-2",   result: "2230000000000000")
//        test("0",      result: "2238000000000000")
//        test("0E+3",   result: "2244000000000000")
//        test("0E+369", result: "43fc000000000000")
//        // clamped zeros...
//        test("0E+370", result: "43fc000000000000") //   Clamped
//        test("0E+384", result: "43fc000000000000") //   Clamped
//        test("0E+400", result: "43fc000000000000") //   Clamped
//        test("0E+500", result: "43fc000000000000") //   Clamped
//
//        // negative zeros
//        test("-0E-400", result: "8000000000000000") //   Clamped
//        test("-0E-400", result: "8000000000000000") //   Clamped
//        test("-0E-398", result: "8000000000000000")
//        test("-0.000000000000000E-383", result: "8000000000000000")
//        test("-0E-2",   result: "a230000000000000")
//        test("-0",      result: "a238000000000000")
//        test("-0E+3",   result: "a244000000000000")
//        test("-0E+369", result: "c3fc000000000000")
//        // clamped zeros...
//        test("-0E+370", result: "c3fc000000000000") //   Clamped
//        test("-0E+384", result: "c3fc000000000000") //   Clamped
//        test("-0E+400", result: "c3fc000000000000") //   Clamped
//        test("-0E+500", result: "c3fc000000000000") //   Clamped
//
//        // exponents
//        test("7E+9",    result: "225c000000000007")
//        test("7E+99",   result: "23c4000000000007")
//
//        // diagnostic NaNs
//        test("NaN",       result: "7c00000000000000")
//        test("NaN0",      result: "7c00000000000000")
//        test("NaN1",      result: "7c00000000000001")
//        test("NaN12",     result: "7c00000000000012")
//        test("NaN79",     result: "7c00000000000079")
//        test("NaN12345",  result: "7c000000000049c5")
//        test("NaN123456", result: "7c00000000028e56")
//        test("NaN799799", result: "7c000000000f7fdf")
//        test("NaN799799799799799", result: "7c03dff7fdff7fdf")
//        test("NaN999999999999999", result: "7c00ff3fcff3fcff")
//
//        // fold-down full sequence
//        test("1E+384", result: "47fc000000000000") //  Clamped
//        test("1E+383", result: "43fc800000000000") //  Clamped
//        test("1E+382", result: "43fc100000000000") //  Clamped
//        test("1E+381", result: "43fc010000000000") //  Clamped
//        test("1E+380", result: "43fc002000000000") //  Clamped
//        test("1E+379", result: "43fc000400000000") //  Clamped
//        test("1E+378", result: "43fc000040000000") //  Clamped
//        test("1E+377", result: "43fc000008000000") //  Clamped
//        test("1E+376", result: "43fc000001000000") //  Clamped
//        test("1E+375", result: "43fc000000100000") //  Clamped
//        test("1E+374", result: "43fc000000020000") //  Clamped
//        test("1E+373", result: "43fc000000004000") //  Clamped
//        test("1E+372", result: "43fc000000000400") //  Clamped
//        test("1E+371", result: "43fc000000000080") //  Clamped
//        test("1E+370", result: "43fc000000000010") //  Clamped
//        test("1E+369", result: "43fc000000000001")
//        test("1E+368", result: "43f8000000000001")
//
//        // same with 9s
//        test("9E+384", result: "77fc000000000000") //  Clamped
//        test("9E+383", result: "43fc8c0000000000") //  Clamped
//        test("9E+382", result: "43fc1a0000000000") //  Clamped
//        test("9E+381", result: "43fc090000000000") //  Clamped
//        test("9E+380", result: "43fc002300000000") //  Clamped
//        test("9E+379", result: "43fc000680000000") //  Clamped
//        test("9E+378", result: "43fc000240000000") //  Clamped
//        test("9E+377", result: "43fc000008c00000") //  Clamped
//        test("9E+376", result: "43fc000001a00000") //  Clamped
//        test("9E+375", result: "43fc000000900000") //  Clamped
//        test("9E+374", result: "43fc000000023000") //  Clamped
//        test("9E+373", result: "43fc000000006800") //  Clamped
//        test("9E+372", result: "43fc000000002400") //  Clamped
//        test("9E+371", result: "43fc00000000008c") //  Clamped
//        test("9E+370", result: "43fc00000000001a") //  Clamped
//        test("9E+369", result: "43fc000000000009")
//        test("9E+368", result: "43f8000000000009")
//
//        // values around [u]int32 edges (zeros done earlier)
//        test(-2147483646, result: "a23800008c78af46")
//        test(-2147483647, result: "a23800008c78af47")
//        test(-2147483648, result: "a23800008c78af48")
//        test(-2147483649, result: "a23800008c78af49")
//        test(2147483646,  result: "223800008c78af46")
//        test(2147483647,  result: "223800008c78af47")
//        test(2147483648,  result: "223800008c78af48")
//        test(2147483649,  result: "223800008c78af49")
//        test(4294967294,  result: "2238000115afb55a")
//        test(4294967295,  result: "2238000115afb55b")
//        test(4294967296,  result: "2238000115afb57a")
//        test(4294967297,  result: "2238000115afb57b")
//    }
//
//    func testEncodingDecimal32() {
//        // Test encoding for Decimal32 strings and integers
//        var testNumber = 0
//
//        func test(_ value: String, result: String) {
//            testNumber += 1
//            if let n = Decimal32(value) {
//                print("Test \(testNumber): \"\(value)\" [\(n)] = \(result.uppercased()) - \(n.numberClass.description)")
//                XCTAssertEqual(n.debugDescription, result.uppercased())
//            } else {
//                XCTAssert(false, "Failed to convert '\(value)'")
//            }
//        }
//
//        func test(_ value: Int, result : String) {
//            testNumber += 1
//            let n = Decimal32(value)
//            print("Test \(testNumber): \(value) [\(n)] = \(result.uppercased()) - \(n.numberClass.description)")
//            XCTAssertEqual(n.debugDescription, result.uppercased())
//        }
//
//        /// Check min/max values
//        XCTAssertEqual(Decimal32.greatestFiniteMagnitude.description, "9.999999E+96")
//        XCTAssertEqual(Decimal32.leastNonzeroMagnitude.description,   "1E-101")
//        XCTAssertEqual(Decimal32.leastNormalMagnitude.description,    "9.999999E-95")
//
//        /// Verify various string and integer encodings
//        test("-7.50",        result: "A23003D0")
//        test("-7.50E+3",     result: "A26003D0")
//        test("-750",         result: "A25003D0")
//        test("-75.0",        result: "A24003D0")
//        test("-0.750",       result: "A22003D0")
//        test("-0.0750",      result: "A21003D0")
//        test("-0.000750",    result: "A1F003D0")
//        test("-0.00000750",  result: "A1D003D0")
//        test("-7.50E-7",     result: "A1C003D0")
//
//        // Normality
//        test(1234567,        result: "2654D2E7")
//        test(-1234567,       result: "a654d2e7")
//        test(1111111,        result: "26524491")
//
//        //Nmax and similar
//        test("9.999999E+96", result: "77f3fcff")
//        test("1.234567E+96", result: "47f4d2e7")
//        test("1.23E+96",     result: "47f4c000")
//        test("1E+96",        result: "47f00000")
//
//        test("12345",        result: "225049c5")
//        test("1234",         result: "22500534")
//        test("123",          result: "225000a3")
//        test("12",           result: "22500012")
//        test("1",            result: "22500001")
//        test("1.23",         result: "223000a3")
//        test("123.45",       result: "223049c5")
//
//        // Nmin and below
//        test("1E-95",        result: "00600001")
//        test("1.000000E-95", result: "04000000")
//        test("1.000001E-95", result: "04000001")
//
//        test("0.100000E-95", result: "00020000")
//        test("0.000010E-95", result: "00000010")
//        test("0.000001E-95", result: "00000001")
//        test("1e-101",       result: "00000001")
//
//        // underflows cannot be tested; just check edge case
//        test("1e-101",       result: "00000001")
//
//        // same again, negatives --
//
//        // Nmax and similar
//        test("-9.999999E+96", result: "f7f3fcff")
//        test("-1.234567E+96", result: "c7f4d2e7")
//        test("-1.23E+96",     result: "c7f4c000")
//        test("-1E+96",        result: "c7f00000")
//
//        test(-12345,          result: "a25049c5")
//        test(-1234,           result: "a2500534")
//        test(-123,            result: "a25000a3")
//        test(-12,             result: "a2500012")
//        test(-1,              result: "a2500001")
//        test("-1.23",         result: "a23000a3")
//        test("-123.45",       result: "a23049c5")
//
//        // Nmin and below
//        test("-1E-95",        result: "80600001")
//        test("-1.000000E-95", result: "84000000")
//        test("-1.000001E-95", result: "84000001")
//
//        test("-0.100000E-95", result: "80020000")
//        test("-0.000010E-95", result: "80000010")
//        test("-0.000001E-95", result: "80000001")
//        test("-1e-101",       result: "80000001")
//
//        // underflow edge case
//        test("-1e-101",       result: "80000001")
//
//        // zeros
//        test("0E-400",       result: "00000000")
//        test("0E-101",       result: "00000000")
//        test("0.000000E-95", result: "00000000")
//        test("0E-2",         result: "22300000")
//        test(0,              result: "22500000")
//        test("0E+3",         result: "22800000")
//        test("0E+90",        result: "43f00000")
//
//        // clamped zeros...
//        test("0E+91",       result: "43f00000")
//        test("0E+96",       result: "43f00000")
//        test("0E+400",      result: "43f00000")
//
//        // negative zeros
//        test("-0E-400",     result: "80000000")
//        test("-0E-101",     result: "80000000")
//        test("-0.000000E-95", result: "80000000")
//        test("-0E-2",       result: "a2300000")
//        test("-0",          result: "a2500000")
//        test("-0E+3",       result: "a2800000")
//        test("-0E+90",      result: "c3f00000")
//        // clamped zeros...
//        test("-0E+91",      result: "c3f00000")
//        test("-0E+96",      result: "c3f00000")
//        test("-0E+400",     result: "c3f00000")
//
//        // Specials
//        test("Infinity",    result: "78000000")
//        test("NaN",         result: "7c000000")
//        test("-Infinity",   result: "f8000000")
//        test("-NaN",        result: "fc000000")
//
//        // diagnostic NaNs
//        test("NaN",         result: "7c000000")
//        test("NaN0",        result: "7c000000")
//        test("NaN1",        result: "7c000001")
//        test("NaN12",       result: "7c000012")
//        test("NaN79",       result: "7c000079")
//        test("NaN12345",    result: "7c0049c5")
//        test("NaN123456",   result: "7c028e56")
//        test("NaN799799",   result: "7c0f7fdf")
//        test("NaN999999",   result: "7c03fcff")
//
//
//        // fold-down full sequence
//        test("1E+96", result: "47f00000")
//        test("1E+95", result: "43f20000")
//        test("1E+94", result: "43f04000")
//        test("1E+93", result: "43f00400")
//        test("1E+92", result: "43f00080")
//        test("1E+91", result: "43f00010")
//        test("1E+90", result: "43f00001")
//
//        // narrowing case
//        test("2.00E-99", result: "00000100")
//    }
    
    func testBooleanOperations() {
        
        var testNumber = 0
        
        func testXor (_ lhs:String, _ rhs:String, _ result:String) {
            testNumber += 1
            let lhsn = HDecimal(lhs)!
            if !HDecimal.context.status.isEmpty {
                print("Number \(lhsn) too large")
            }
            let rhsn = HDecimal(rhs)!
            if !HDecimal.context.status.isEmpty {
                print("Number \(rhsn) too large")
            }
            let n = lhsn.xor(rhsn)
            if !HDecimal.context.status.isEmpty {
                print("Invalid operation")
            }
            print("Test \(testNumber): \(lhs) xor \(rhs) -> \(result)")
            XCTAssertEqual(n.description.uppercased(), result.trimmingCharacters(in: .whitespaces).uppercased())
        }
        
        func testOr (_ lhs:String, _ rhs:String, _ result:String) {
            testNumber += 1
            let lhsn = HDecimal(lhs)!, rhsn = HDecimal(rhs)!
            let n = lhsn.or(rhsn)
            print("Test \(testNumber): \(lhs) or \(rhs) -> \(result)")
            XCTAssertEqual(n.description.uppercased(), result.trimmingCharacters(in: .whitespaces).uppercased())
        }
        
        // Note: The following tests use a built-in feature of the CDecNumber library that can evaluate
        //       boolean numbers encoded as BCD digits as long as only `0` and `1` digits are used.
        HDecimal.digits = 9   // defines the maximum length of the number in BCD digits
        
        // sanity check (truth table)
        testXor(   "0",    "0",    "0")
        testXor(   "0",    "1",    "1")
        testXor(   "1",    "0",    "1")
        testXor(   "1",    "1",    "0")
        testXor("1100", "1010",  "110")
        testXor("1111",   "10", "1101")
        // and at msd and msd-1
        testXor("000000000", "000000000", "        0")
        testXor("000000000", "100000000", "100000000")
        testXor("100000000", "000000000", "100000000")
        testXor("100000000", "100000000", "        0")
        testXor("000000000", "000000000", "        0")
        testXor("000000000", "010000000", " 10000000")
        testXor("010000000", "000000000", " 10000000")
        testXor("010000000", "010000000", "        0")
        
        // Various lengths
        //       123456789         123456789
        testXor("111111111",      "111111111", "0")
        testXor("111111111111",   "111111111", "0")
        testXor(" 11111111",      " 11111111", "0")
        testXor("  1111111",      "  1111111", "0")
        testXor("   111111",      "   111111", "0")
        testXor("    11111",      "    11111", "0")
        testXor("     1111",      "     1111", "0")
        testXor("      111",      "      111", "0")
        testXor("       11",      "       11", "0")
        testXor("        1",      "        1", "0")
        testXor("111111111111", " 1111111111", "0")
        testXor("11111111111", " 11111111111", "0")
        testXor("1111111111", " 111111111111", "0")
        testXor("111111111", " 1111111111111", "0")

        testXor("111111111", "111111111111", "0")
        testXor("11111111",  "111111111111", "100000000")
        testXor("11111111",     "111111111", "100000000")
        testXor(" 1111111",     "100000010", "101111101")
        testXor("  111111",     "100000100", "100111011")
        testXor("   11111",     "100001000", "100010111")
        testXor("    1111",     "100010000", "100011111")
        testXor("     111",     "100100000", "100100111")
        testXor("      11",     "101000000", "101000011")
        testXor("       1",     "110000000", "110000001")

        testXor("1111111111",  "1", "111111110")
        testXor(" 111111111",  "1", "111111110")
        testXor("  11111111",  "1", "11111110")
        testXor("   1111111",  "1", "1111110")
        testXor("    111111",  "1", "111110")
        testXor("     11111",  "1", "11110")
        testXor("      1111",  "1", "1110")
        testXor("       111",  "1", "110")
        testXor("        11",  "1", "10")
        testXor("         1",  "1", "0")

        testXor("1111111111",  "0", "111111111")
        testXor(" 111111111",  "0", "111111111")
        testXor("  11111111",  "0", "11111111")
        testXor("   1111111",  "0", "1111111")
        testXor("    111111",  "0", "111111")
        testXor("     11111",  "0", "11111")
        testXor("      1111",  "0", "1111")
        testXor("       111",  "0", "111")
        testXor("        11",  "0", "11")
        testXor("         1",  "0", "1")

        testXor("1", "1111111111", "111111110")
        testXor("1", " 111111111", "111111110")
        testXor("1", "  11111111", "11111110")
        testXor("1", "   1111111", "1111110")
        testXor("1", "    111111", "111110")
        testXor("1", "     11111", "11110")
        testXor("1", "      1111", "1110")
        testXor("1", "       111", "110")
        testXor("1", "        11", "10")
        testXor("1", "         1", "0")

        testXor("0", "1111111111", "111111111")
        testXor("0", " 111111111", "111111111")
        testXor("0", "  11111111", "11111111")
        testXor("0", "   1111111", "1111111")
        testXor("0", "    111111", "111111")
        testXor("0", "     11111", "11111")
        testXor("0", "      1111", "1111")
        testXor("0", "       111", "111")
        testXor("0", "        11", "11")
        testXor("0", "         1", "1")

        testXor("011111111", "111101111", "100010000")
        testXor("101111111", "111101111", " 10010000")
        testXor("110111111", "111101111", "  1010000")
        testXor("111011111", "111101111", "   110000")
        testXor("111101111", "111101111", "        0")
        testXor("111110111", "111101111", "    11000")
        testXor("111111011", "111101111", "    10100")
        testXor("111111101", "111101111", "    10010")
        testXor("111111110", "111101111", "    10001")

        testXor("111101111", "011111111", "100010000")
        testXor("111101111", "101111111", " 10010000")
        testXor("111101111", "110111111", "  1010000")
        testXor("111101111", "111011111", "   110000")
        testXor("111101111", "111101111", "        0")
        testXor("111101111", "111110111", "    11000")
        testXor("111101111", "111111011", "    10100")
        testXor("111101111", "111111101", "    10010")
        testXor("111101111", "111111110", "    10001")
        
        // non-0/1 should not be accepted, nor should signs
        testXor("111111112", "111111111", "NaN") // Invalid_operation
        testXor("333333333", "333333333", "NaN") // Invalid_operation
        testXor("555555555", "555555555", "NaN") // Invalid_operation
        testXor("777777777", "777777777", "NaN") // Invalid_operation
        testXor("999999999", "999999999", "NaN") // Invalid_operation
        testXor("222222222", "999999999", "NaN") // Invalid_operation
        testXor("444444444", "999999999", "NaN") // Invalid_operation
        testXor("666666666", "999999999", "NaN") // Invalid_operation
        testXor("888888888", "999999999", "NaN") // Invalid_operation
        testXor("999999999", "222222222", "NaN") // Invalid_operation
        testXor("999999999", "444444444", "NaN") // Invalid_operation
        testXor("999999999", "666666666", "NaN") // Invalid_operation
        testXor("999999999", "888888888", "NaN") // Invalid_operation
        // a few randoms
        testXor(" 567468689", "-934981942", "NaN") // Invalid_operation
        testXor(" 567367689", " 934981942", "NaN") // Invalid_operation
        testXor("-631917772", "-706014634", "NaN") // Invalid_operation
        testXor("-756253257", " 138579234", "NaN") // Invalid_operation
        testXor(" 835590149", " 567435400", "NaN") // Invalid_operation
        // test MSD
        testXor("200000000", "100000000", "NaN") // Invalid_operation
        testXor("700000000", "100000000", "NaN") // Invalid_operation
        testXor("800000000", "100000000", "NaN") // Invalid_operation
        testXor("900000000", "100000000", "NaN") // Invalid_operation
        testXor("200000000", "000000000", "NaN") // Invalid_operation
        testXor("700000000", "000000000", "NaN") // Invalid_operation
        testXor("800000000", "000000000", "NaN") // Invalid_operation
        testXor("900000000", "000000000", "NaN") // Invalid_operation
        testXor("100000000", "200000000", "NaN") // Invalid_operation
        testXor("100000000", "700000000", "NaN") // Invalid_operation
        testXor("100000000", "800000000", "NaN") // Invalid_operation
        testXor("100000000", "900000000", "NaN") // Invalid_operation
        testXor("000000000", "200000000", "NaN") // Invalid_operation
        testXor("000000000", "700000000", "NaN") // Invalid_operation
        testXor("000000000", "800000000", "NaN") // Invalid_operation
        testXor("000000000", "900000000", "NaN") // Invalid_operation
        // test MSD-1
        testXor("020000000", "100000000", "NaN") // Invalid_operation
        testXor("070100000", "100000000", "NaN") // Invalid_operation
        testXor("080010000", "100000001", "NaN") // Invalid_operation
        testXor("090001000", "100000010", "NaN") // Invalid_operation
        testXor("100000100", "020010100", "NaN") // Invalid_operation
        testXor("100000000", "070001000", "NaN") // Invalid_operation
        testXor("100000010", "080010100", "NaN") // Invalid_operation
        testXor("100000000", "090000010", "NaN") // Invalid_operation
        // test LSD
        testXor("001000002", "100000000", "NaN") // Invalid_operation
        testXor("000000007", "100000000", "NaN") // Invalid_operation
        testXor("000000008", "100000000", "NaN") // Invalid_operation
        testXor("000000009", "100000000", "NaN") // Invalid_operation
        testXor("100000000", "000100002", "NaN") // Invalid_operation
        testXor("100100000", "001000007", "NaN") // Invalid_operation
        testXor("100010000", "010000008", "NaN") // Invalid_operation
        testXor("100001000", "100000009", "NaN") // Invalid_operation
        // test Middie
        testXor("001020000", "100000000", "NaN") // Invalid_operation
        testXor("000070001", "100000000", "NaN") // Invalid_operation
        testXor("000080000", "100010000", "NaN") // Invalid_operation
        testXor("000090000", "100001000", "NaN") // Invalid_operation
        testXor("100000010", "000020100", "NaN") // Invalid_operation
        testXor("100100000", "000070010", "NaN") // Invalid_operation
        testXor("100010100", "000080001", "NaN") // Invalid_operation
        testXor("100001000", "000090000", "NaN") // Invalid_operation
        // signs
        testXor("-100001000", "-000000000", "NaN") // Invalid_operation
        testXor("-100001000", " 000010000", "NaN") // Invalid_operation
        testXor(" 100001000", "-000000000", "NaN") // Invalid_operation
        testXor(" 100001000", " 000011000", "100010000")
        
        // Nmax, Nmin, Ntiny
        testXor("2", "9.99999999E+999", "NaN") // Invalid_operation
        testXor("3", "1E-999         ", "NaN") // Invalid_operation
        testXor("4", "1.00000000E-999", "NaN") // Invalid_operation
        testXor("5", "1E-1007        ", "NaN") // Invalid_operation
        testXor("6", "-1E-1007       ", "NaN") // Invalid_operation
        testXor("7", "-1.00000000E-99", "NaN") // Invalid_operation
        testXor("8", "-1E-999        ", "NaN") // Invalid_operation
        testXor("9", "-9.99999999E+99", "NaN") // Invalid_operation
        testXor("9.99999999E+999 ", "-18", "NaN") // Invalid_operation
        testXor("1E-999          ", " 01", "NaN") // Invalid_operation
        testXor("1.00000000E-999 ", "-18", "NaN") // Invalid_operation
        testXor("1E-1007         ", " 18", "NaN") // Invalid_operation
        testXor("-1E-1007        ", "-10", "NaN") // Invalid_operation
        testXor("-1.00000000E-999", " 18", "NaN") // Invalid_operation
        testXor("-1E-999         ", " 10", "NaN") // Invalid_operation
        testXor("-9.99999999E+999", "-18", "NaN") // Invalid_operation

        // A few other non-integers
        testXor("1.0 ", "1", "NaN") // Invalid_operation
        testXor("1E+1", "1", "NaN") // Invalid_operation
        testXor("0.0 ", "1", "NaN") // Invalid_operation
        testXor("0E+1", "1", "NaN") // Invalid_operation
        testXor("9.9 ", "1", "NaN") // Invalid_operation
        testXor("9E+1", "1", "NaN") // Invalid_operation
        testXor("0", "1.0 ", "NaN") // Invalid_operation
        testXor("0", "1E+1", "NaN") // Invalid_operation
        testXor("0", "0.0 ", "NaN") // Invalid_operation
        testXor("0", "0E+1", "NaN") // Invalid_operation
        testXor("0", "9.9 ", "NaN") // Invalid_operation
        testXor("0", "9E+1", "NaN") // Invalid_operation
        
    }
    
//    func testStringToDecima") //l() {
//
//        measure {
//            let _ = HDecimal(Utilities.piString)
//        }
//
//    }
    
}

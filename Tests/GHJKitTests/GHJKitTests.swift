import XCTest
import Foundation
@testable import GHJKit

final class GHJKitTests: XCTestCase {
    func testExample() async throws {
//        let data = try await ghjKitDownCerFile(
//            url: "https://raw.githubusercontent.com/titilone/GHJKit/main/cer_flie.txt"
//        )
//        let dict = try JSONSerialization.jsonObject(with: data, options: [])
//        print("------dict:\(dict)")
        GHJLog.printNormal("\n\n")
        let str = "2026.11-04 15:40:39"

        let localStr = str.ghj.convertUTCWithoutTimeZoneToLocalTime()
        GHJLog.printNormal("utc time:\(str) to local time:\(localStr ?? "")\n")

        let date = str.ghj.getDate()
        let dateStr = date?.ghj.toUTCTimeString(abbreviation: "GMT-01:01")
        GHJLog.printNormal("cur time:\(str) to utc(GMT-01:01) time:\(dateStr ?? "")\n")

        let localTimeString = Date.ghj.timeIntervalToLocalTimeString(timeInterval: date?.timeIntervalSince1970 ?? 0)
        GHJLog.printNormal("timeinterval to local time string:\(localTimeString)\n")

        let utcTimeStr = Date.ghj.timeIntervalToUTCTimeString(timeInterval: date?.timeIntervalSince1970 ?? 0)
        GHJLog.printNormal("timeinterval to utc time:\(utcTimeStr)\n")

        let zeroClock = date?.ghj.zeroStringClock
        GHJLog.printNormal("cur time:\(str) to zero clock:\(zeroClock ?? "")")

        GHJLog.printNormal("\n\n")
    }

    /// 字符串截取（ghj 命名空间）基础行为
    func testSubString() {
        XCTAssertEqual("abcdef".ghj.subString(from: 1, to: 4), "bcd")
        XCTAssertEqual("abcdef".ghj.subString(from: 2), "cdef")
        XCTAssertEqual("abcdef".ghj.subString(to: 2), "ab")
        // 非法索引与 from > to 返回 nil，不崩溃
        XCTAssertNil("abcdef".ghj.subString(from: 4, to: 2))
        XCTAssertNil("abcdef".ghj.subString(to: 99))
        // 按字符计数，Emoji 安全
        XCTAssertEqual("你好🇨🇳ab".ghj.subString(from: 1, to: 3), "好🇨🇳")
    }
}

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
        printNormal("\n\n")
        let str = "2026.11-04 15:40:39"
        
        let localStr = str.convertUTCWithoutTimeZoneToLocalTime()
        printNormal("utc time:\(str) to local time:\(localStr ?? "")\n")
        
        let date = str.getDate()
        let dateStr = date?.toUTCString(abbreviation: "GMT-01:01")
        printNormal("cur time:\(str) to utc(GMT-01:01) time:\(dateStr ?? "")\n")
        
        let localTimeString = Date.timeIntervalToLocalTimeString(timeInterval: date?.timeIntervalSince1970 ?? 0)
        printNormal("timeinterval to local time string:\(localTimeString)\n")
        
        let utcTimeStr = Date.timeIntervalToUTCString(timeInterval: date?.timeIntervalSince1970 ?? 0)
        printNormal("timeinterval to utc time:\(utcTimeStr)\n")
        
        let zeroClock = date?.zeroClock
        printNormal("cur time:\(str) to zero clock:\(zeroClock ?? "")")
        
        
        let possibleNumber: Int? = Int("42")
        let nonOverflowingSquare = possibleNumber.flatMap { x -> Int? in
            let (result, overflowed) = x.multipliedReportingOverflow(by: x)
            return overflowed ? nil : result
        }
        printNormal(nonOverflowingSquare)
        
        printNormal("\n\n")
        
        
    }
}

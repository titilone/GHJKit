import XCTest
import Foundation
@testable import GHJKit

final class GHJKitTests: XCTestCase {
    func testExample() async throws {
        let data = try await ghjKitDownCerFile(
            url: "https://raw.githubusercontent.com/titilone/GHJKit/main/cer_flie.txt"
        )
//        var str = String(data: data, encoding: .utf8)
//        str = str?.replacing("\n", with: "")
//        str = str?.replacing("  ", with: "")
        // let formatData = data//str?.data(using: .utf8)
//        print("------str:\(String(describing: str))")
        let dict = try JSONSerialization.jsonObject(with: data, options: [])
        print("------dict:\(dict)")
    }
}

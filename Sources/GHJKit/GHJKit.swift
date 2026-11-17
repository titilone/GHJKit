// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public func ghjKitDownCerFile(url: String) async throws -> Data {
    try await ghjKitDownloadWith(url: url)
}

fileprivate func ghjKitDownloadWith(url: String) async throws -> Data {
    guard
        let downloadURL = URL(string: url),
        let scheme = downloadURL.scheme?.lowercased(),
        ["http", "https"].contains(scheme),
        downloadURL.host != nil
    else {
        throw URLError(.badURL)
    }

    do{
        let (data,rps) = try await URLSession.shared.data(from: downloadURL)
        guard
            let response = rps as? HTTPURLResponse,
            (200..<300).contains(response.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        
        return data

    } catch (let error){
        throw error
    }
    
}

func printNormal(_ message: Any) {
    printTime("~~~ \(message)")
}

func printSuccess(_ message: Any) {
    printTime("~~~✅ \(message)")
}

func printWaring(_ message: Any) {
    printTime("~~~⚠️ \(message)")
}

func printError(_ message: Any) {
    printTime("~~~❌ \(message)")
}

// 优化：使用静态的 DateFormatter 避免重复创建
private let logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
    return formatter
}()

fileprivate func printTime(_ message: String, function: String = #function) {
    let timestamp = logDateFormatter.string(from: Date())
    print("\(timestamp) : \(message)\n")
}


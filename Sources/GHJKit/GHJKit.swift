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

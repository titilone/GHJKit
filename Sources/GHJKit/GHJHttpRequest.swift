//
//  GHJHttpRequest.swift
//  GHJKit
//
//  Created by gaohj on 2026/11/17.
//

import Foundation

/// HTTP 请求方法
public enum GHJHttpMethod: String {
    case get, post, put, delete, head, patch
}

/// HTTP 请求相关错误
public enum GHJHttpRequestError: LocalizedError {
    /// URL 字符串非法 / scheme 非 http(s)
    case invalidURL(String)
    /// 响应非 HTTPURLResponse
    case invalidResponse
    /// HTTP 状态码非 2xx（携带状态码与响应体）
    case httpStatus(Int, Data?)
    /// 解码失败（携带原始数据与底层错误）
    case decodeFailed(Data, Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL 非法：\(url)"
        case .invalidResponse:
            return "响应类型错误（非 HTTPURLResponse）"
        case .httpStatus(let code, let data):
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            return "HTTP 状态码 \(code)，响应体：\(body)"
        case .decodeFailed(_, let error):
            return "响应解码失败：\(error.localizedDescription)"
        }
    }
}

/// HTTP 请求配置
public struct GHJHttpRequestConfig {
    /// 全局默认配置（非线程安全，建议在 App 启动时一次性设置；之后视为只读）
    public nonisolated(unsafe) static var `default` = GHJHttpRequestConfig()

    /// 超时时间（秒），默认 30
    public var timeout: TimeInterval

    /// 默认请求头（会与每次请求的 headers 合并，请求级优先）
    public var defaultHeaders: [String: String]

    /// 复用的 URLSession（默认 shared）
    public var session: URLSession

    public init(
        timeout: TimeInterval = 30,
        defaultHeaders: [String: String] = [:],
        session: URLSession = .shared
    ) {
        self.timeout = timeout
        self.defaultHeaders = defaultHeaders
        self.session = session
    }
}

/// HTTP 请求封装（回调风格）
public class GHJHttpRequest {

    // MARK: - 底层构造

    /// 构造 URLRequest + URL（含 query），非法时 throw；仅在发起请求前同步执行
    private static func buildRequest(
        url: String,
        method: GHJHttpMethod,
        headers: [String: String],
        query: [String: String],
        body: Data?,
        config: GHJHttpRequestConfig
    ) throws -> URLRequest {
        guard var components = URLComponents(string: url),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host != nil else {
            throw GHJHttpRequestError.invalidURL(url)
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let requestURL = components.url else {
            throw GHJHttpRequestError.invalidURL(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue.uppercased()
        request.timeoutInterval = config.timeout

        var merged = config.defaultHeaders
        headers.forEach { merged[$0.key] = $0.value }
        merged.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body, !["GET", "HEAD"].contains(request.httpMethod ?? "") {
            request.httpBody = body
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }

    /// 校验响应：把 dataTask 的三元组转换为 Result<(Data, HTTPURLResponse), Error>
    private static func validate(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<(Data, HTTPURLResponse), Error> {
        if let error { return .failure(error) }
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(GHJHttpRequestError.invalidResponse)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            return .failure(GHJHttpRequestError.httpStatus(httpResponse.statusCode, data))
        }
        return .success((data ?? Data(), httpResponse))
    }

    // MARK: - 核心请求

    /// 发起一次 HTTP 请求（回调风格）
    ///
    /// 错误分两种传播方式：
    /// - **同步 throw**：URL 非法 / scheme 非 http(s) —— 请求还没发就已知错误，函数直接 throw，不会触发 completion
    /// - **Result.failure**：网络错误 / 状态码异常 / 响应类型错误 —— 请求发出后才知道的错误，通过 completion 传回
    ///
    /// - Returns: URLSessionDataTask，可用于取消（`task.cancel()`）
    @discardableResult
    public static func request(
        url: String,
        method: GHJHttpMethod = .get,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        body: Data? = nil,
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<(Data, HTTPURLResponse), Error>) -> Void
    ) throws -> URLSessionDataTask {
        let request = try buildRequest(url: url, method: method, headers: headers, query: query, body: body, config: config)
        let task = config.session.dataTask(with: request) { data, response, error in
            completion(validate(data: data, response: response, error: error))
        }
        task.resume()
        return task
    }

    // MARK: - GET

    @discardableResult
    public static func get(
        url: String,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<Data, Error>) -> Void
    ) throws -> URLSessionDataTask {
        try request(url: url, method: .get, headers: headers, query: query, config: config) { result in
            completion(result.map(\.0))
        }
    }

    /// GET 直接解码为 Decodable（要求 T 同时满足 Sendable，因为解码结果跨 closure 传递）
    @discardableResult
    public static func get<T: Decodable & Sendable>(
        url: String,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder(),
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<T, Error>) -> Void
    ) throws -> URLSessionDataTask {
        try request(url: url, method: .get, headers: headers, query: query, config: config) { result in
            switch result {
            case .success((let data, _)):
                do { completion(.success(try decoder.decode(T.self, from: data))) }
                catch { completion(.failure(GHJHttpRequestError.decodeFailed(data, error))) }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - POST

    @discardableResult
    public static func post(
        url: String,
        json: Encodable? = nil,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<Data, Error>) -> Void
    ) throws -> URLSessionDataTask {
        let body: Data? = try json.map { try JSONEncoder().encode($0) }
        return try request(url: url, method: .post, headers: headers, query: query, body: body, config: config) { result in
            completion(result.map(\.0))
        }
    }

    /// POST 直接解码为 Decodable（要求 T 同时满足 Sendable，因为解码结果跨 closure 传递）
    @discardableResult
    public static func post<T: Decodable & Sendable>(
        url: String,
        json: Encodable? = nil,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder(),
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<T, Error>) -> Void
    ) throws -> URLSessionDataTask {
        let body: Data? = try json.map { try JSONEncoder().encode($0) }
        return try request(url: url, method: .post, headers: headers, query: query, body: body, config: config) { result in
            switch result {
            case .success((let data, _)):
                do { completion(.success(try decoder.decode(T.self, from: data))) }
                catch { completion(.failure(GHJHttpRequestError.decodeFailed(data, error))) }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - PUT / DELETE

    @discardableResult
    public static func put(
        url: String,
        json: Encodable? = nil,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<Data, Error>) -> Void
    ) throws -> URLSessionDataTask {
        let body: Data? = try json.map { try JSONEncoder().encode($0) }
        return try request(url: url, method: .put, headers: headers, query: query, body: body, config: config) { result in
            completion(result.map(\.0))
        }
    }

    @discardableResult
    public static func delete(
        url: String,
        headers: [String: String] = [:],
        query: [String: String] = [:],
        config: GHJHttpRequestConfig = .default,
        completion: @escaping @Sendable (Result<Data, Error>) -> Void
    ) throws -> URLSessionDataTask {
        try request(url: url, method: .delete, headers: headers, query: query, config: config) { result in
            completion(result.map(\.0))
        }
    }

    // MARK: - 下载（保留旧接口，改为回调）

    /// 下载文件
    @discardableResult
    public func ghjKitDownCerFile(
        url: String,
        completion: @escaping @Sendable (Result<Data, Error>) -> Void
    ) throws -> URLSessionDataTask {
        try Self.request(url: url, method: .get) { result in
            completion(result.map(\.0))
        }
    }
}

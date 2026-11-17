import Foundation

/// 日志工具类
public class GHJLog {
    /// 日志级别
    public enum LogLevel {
        case normal
        case success
        case warning
        case error
    }

    /// 优化：使用静态的 DateFormatter 避免重复创建
    private static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")   // 固定公历 + ASCII 数字
        formatter.timeZone = TimeZone.current                   // 当前时区
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        return formatter
    }()

    /// 打印 / 写入一条日志（带时间戳）
    private static func printTime(_ message: String, logLevel: LogLevel = .normal) {
        let timestamp = logDateFormatter.string(from: Date())
        let fullLine = "\(timestamp) : \(message)\n"
        Swift.print(fullLine, terminator: "")   // 显式引用 Swift 全局 print，避免和本类静态方法 print 重名遮蔽
        writeToFileIfEnabled(fullLine)   // 开启文件日志时双写
    }

    /// 打印普通日志
    public static func printNormal(_ message: Any) {
        printTime("~~~ \(message)", logLevel: .normal)
    }

    /// 打印成功日志
    public static func printSuccess(_ message: Any) {
        printTime("~~~✅ \(message)", logLevel: .success)
    }

    /// 打印警告日志
    public static func printWaring(_ message: Any) {
        printTime("~~~⚠️ \(message)", logLevel: .warning)
    }

    /// 打印错误日志
    public static func printError(_ message: Any) {
        printTime("~~~❌ \(message)", logLevel: .error)
    }

    /// 打印日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - logLevel: 日志级别
    public static func print(_ message: Any, logLevel: LogLevel = .normal) {
        printTime("~~~ \(message)", logLevel: logLevel)
    }
}

// MARK: - 文件日志

/// 日志保存到文件逻辑
public extension GHJLog {

    // MARK: - 默认路径 & 配置

    /// 默认日志目录：~/Library/Logs/GHJKit/
    /// - iOS Sandbox: 落到 App 的 Library/Logs/GHJKit/
    /// - macOS: 落到当前用户的 ~/Library/Logs/GHJKit/
    static let defaultLogDirectory: URL = {
        let paths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Logs/GHJKit", isDirectory: true)
    }()

    /// 是否开启文件日志（默认关闭，避免用户无意写入磁盘）
    /// - Note: 该属性读写由内部 NSLock 保护，并发安全，故标注 nonisolated(unsafe) 关闭 Swift 6 检查
    nonisolated(unsafe) static var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                // 开启时确保目录存在
                createDirectoryIfNeeded(effectiveLogDirectory)
            } else {
                closeFile()
            }
        }
    }

    /// 外部指定日志目录，传 nil 恢复默认路径
    static func setLogDirectory(_ directory: URL?) {
        lock.lock()
        defer { lock.unlock() }
        configuredLogDirectory = directory
        closeFileHandleLocked()
        createDirectoryIfNeeded(effectiveLogDirectory)
    }

    /// 当前实际生效的日志目录（外部设置优先，否则回落到默认）
    static var effectiveLogDirectory: URL {
        return configuredLogDirectory ?? defaultLogDirectory
    }

    // MARK: - 内部状态（串行写文件）

    /// 外部可覆盖的日志目录（内部访问由 NSLock 保护）
    private nonisolated(unsafe) static var configuredLogDirectory: URL?

    /// 串行队列：保证多次 async 调用在队列里串行执行，避免并发 open/seek/write
    private static let fileQueue = DispatchQueue(label: "com.ghjkit.log.file", qos: .utility)

    /// 锁：保护 fileHandle 与 currentOpenPath 这两个状态变量
    private static let lock = NSLock()

    /// 当前打开的文件句柄（复用避免频繁 open/close；由 NSLock + 串行队列保护）
    private nonisolated(unsafe) static var fileHandle: FileHandle?

    /// fileHandle 当前对应的文件路径，用于日期滚动时判断是否需要切换（由 NSLock 保护）
    private nonisolated(unsafe) static var currentOpenPath: String?

    // MARK: - 路径计算

    /// 按日期滚动的日志文件 URL，如 GHJLog_2026-11-17.log
    static var currentLogFileURL: URL? {
        let dir = effectiveLogDirectory
        let datePrefix = logDateFormatter.string(from: Date()).prefix(10)
        return dir.appendingPathComponent("GHJLog_\(datePrefix).log")
    }

    // MARK: - 写入

    /// 写入一条日志行到当前文件（线程安全、自动日期滚动、自动 flush）
    /// - Note: 内部通过 fileQueue 串行化；外部不需要在自己的锁下调用
    static func writeToFileIfEnabled(_ line: String) {
        guard loggingEnabled else { return }
        fileQueue.async {
            writeLine(line)
        }
    }

    /// 同步追加写入（内部实际逻辑，在 fileQueue 上串行化）
    private static func writeLine(_ line: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let fileURL = currentLogFileURL else { return }
        let path = fileURL.path

        // 日期滚动：目标路径变了，关闭旧句柄
        if let openPath = currentOpenPath, openPath != path {
            closeFileHandleLocked()
        }

        // 首次 / 滚动后重新打开
        if fileHandle == nil {
            createDirectoryIfNeeded(effectiveLogDirectory)
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil)
            }
            guard let handle = try? FileHandle(forWritingTo: fileURL) else {
                // 打开失败（权限等）：关掉句柄，下次再试
                closeFileHandleLocked()
                return
            }
            handle.seekToEndOfFile()
            fileHandle = handle
            currentOpenPath = path
        }

        guard let handle = fileHandle,
              let data = (line.hasSuffix("\n") ? line : (line + "\n")).data(using: .utf8) else {
            return
        }
        handle.write(data)
        try? handle.synchronize()
    }

    /// 关闭文件句柄（应用退出 / 目录变更 / 关闭日志时调用）
    static func closeFile() {
        fileQueue.async {
            lock.lock()
            defer { lock.unlock() }
            closeFileHandleLocked()
        }
    }

    // MARK: - 读取

    /// 读取当前日志目录下的所有 `.log` 文件，按最后修改时间倒序返回
    /// - Parameter limit: 限制返回的文件数，0 表示不限制
    static func readAllLogs(limit: Int = 0) -> [(filename: String, content: String)] {
        let dir = effectiveLogDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let sorted = files
            .filter { $0.pathExtension == "log" }
            .sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return da > db
            }

        let capped = limit == 0 ? sorted : Array(sorted.prefix(limit))
        return capped.compactMap { url -> (String, String)? in
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return (url.lastPathComponent, content)
        }
    }

    /// 读取指定日期的日志（文件名格式 `GHJLog_yyyy-MM-dd.log`）
    /// - Parameter dateString: 日期字符串，如 "2026-11-17"
    static func readLog(for dateString: String) -> String? {
        let url = effectiveLogDirectory.appendingPathComponent("GHJLog_\(dateString).log")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// 读取最新日志文件的最后 N 行
    static func readLastLines(_ count: Int) -> String {
        guard let (_, content) = readAllLogs(limit: 1).first else { return "" }
        return content.split(separator: "\n", omittingEmptySubsequences: false)
            .suffix(count)
            .joined(separator: "\n")
    }

    // MARK: - 清理

    /// 清理指定天数之前的旧日志文件（默认保留最近 7 天）
    /// - Returns: 本次清理的文件数量
    @discardableResult
    static func purgeOldLogs(olderThanDays days: Int = 7) -> Int {
        let dir = effectiveLogDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return 0 }

        let cutoff = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        var removed = 0
        for url in files where url.pathExtension == "log" {
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            if let modDate = values?.contentModificationDate, modDate < cutoff {
                try? FileManager.default.removeItem(at: url)
                removed += 1
            }
        }
        return removed
    }

    // MARK: - 私有辅助

    private static func closeFileHandleLocked() {
        try? fileHandle?.close()
        fileHandle = nil
        currentOpenPath = nil
    }

    private static func createDirectoryIfNeeded(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}

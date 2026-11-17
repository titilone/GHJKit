//
//  StringExtension.swift
//  GHJKit
//
//  Created by gaohj on 2026/11/10.
//
import Foundation

extension String {
    
    /// 将"本地时间"字符串解析为 `Date`（把字符串当作设备当前时区的墙上时间）
    /// - Parameter format: 字符串格式，默认 "yyyy-MM-dd HH:mm:ss"
    /// - Returns: 解析成功返回 `Date`，失败返回 nil
    /// - Note: 固定 `en_US_POSIX`，避免设备区域设置（12/24 小时制偏好、佛历日历、非 ASCII 数字等）干扰解析
    func getDate(format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")   // 固定 POSIX locale，解析结果不随设备区域变化
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current                  // 无时区标记的字符串按当前时区解释
        return formatter.date(from: self)
    }
    
    /// 取时间字符串中的"时刻"部分（时:分:秒），换算为从当天 0 点起累计的秒数
    /// - 接受 "2026-11-04 00:40:39" 这类含日期前缀的串（取最后一个空格之后的部分），也接受纯 "00:40:39"
    /// - 要求冒号分隔且恰好 3 段（时、分、秒）且均可转为整数，否则返回 nil
    /// - Warning: 不校验取值范围，"30:99:99" 会得到 108599；返回 `Double` 便于直接参与时间间隔运算
    var offsetSecond: Double? {
        // 取最后一个空格之后的部分得到 "HH:mm:ss"；没有空格则取整个字符串
        guard let hms = self.components(separatedBy: " ").last?.components(separatedBy: ":") else { return nil }
        // 时刻必须是 时:分:秒 三段
        if hms.count != 3 { return nil }
        guard let hour = Int(hms[0]), let minute = Int(hms[1]), let second = Int(hms[2]) else { return nil }
        return Double(hour * 3600 + minute * 60 + second)
    }
    
    /// 将不带时区标记的时间字符串按 UTC 解释，转换为 Unix 时间戳（秒）
    /// - Parameter dateFormat: 字符串格式，默认 "yyyy-MM-dd HH:mm:ss"
    /// - Returns: 解析成功返回时间戳，失败返回 nil
    /// - Warning: 字符串若带 `Z` / `±HH:mm` 等时区标记，标记会被忽略并硬按 UTC 解析，这类输入请改用 `convertUTCToLocalTime` 系列方法
    func convertUTCWithoutTimeZoneToLocalTimeinterval(dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> Double?{
        // 1. 解析：固定 en_US_POSIX + UTC，避免受设备区域、时区影响
        //    由于时区固定为 UTC（secondsFromGMT = 0），解析结果即真实时刻，timeIntervalSince1970 与时区无关
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = dateFormat

        guard let date = parser.date(from: self) else {
            printError("无法解析日期字符串：\(self) / \(dateFormat)")
            return nil
        }
        
        return date.timeIntervalSince1970
    }
    
    /// 将**不带时区标记**的时间字符串按 UTC 解释，转换成设备当前时区的时间字符串
    /// 典型场景：服务端返回 "2026-11-04 00:40:39" 这类未标明时区的 UTC 时间
    /// - Parameter dateFormat: 输入与输出共用同一格式，默认 "yyyy-MM-dd HH:mm:ss"
    /// - Returns: 当前时区的时间字符串，解析失败返回 nil
    /// - Warning: 与 `convertUTCWithoutTimeZoneToLocalTimeinterval` 相同，输入自带的时区标记会被忽略；带标记的输入请用 `convertUTCToLocalTime`
    func convertUTCWithoutTimeZoneToLocalTime(dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String? {
        // 1. 解析：固定 en_US_POSIX + UTC，把无标记字符串当作 UTC 墙上时间读成真实时刻
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = dateFormat

        guard let date = parser.date(from: self) else {
            printError("无法解析日期字符串：\(self) / \(dateFormat)")
            return nil
        }

        // 2. 输出：仅把时区切换为设备当前时区；格式与 locale 保持不变，保证输出结构稳定
        //    偏移量由两个 timeZone 的差值自动完成（如 UTC+8 会 +8 小时）
        let outputter = DateFormatter()
        outputter.locale = Locale(identifier: "en_US_POSIX")
        outputter.timeZone = TimeZone.current
        outputter.dateFormat = dateFormat

        return outputter.string(from: date)
    }
    
    /// utc时间转为当前时区时间
    ///
    /// 时区标记（末尾的 `Z` / `z` 或 `±HH:mm` / `±HHmm` / `±HH` 偏移）处理规则：
    /// 1. 输入不带任何时区标记：无法判定为 UTC，视为已经是本地时间，原样返回；
    /// 2. 输入带时区标记、`dateFormat` 也带时区字段（如 `yyyy-MM-dd HH:mm:ssZ`）：
    ///    按 `dateFormat` 解析，输出时去掉末尾的时区字段（`Z`/`z`/`X`/`x`/`O`/`V` 均可，含引号字面量场景）；
    /// 3. 输入带时区标记、`dateFormat` 不带时区字段（如 `yyyy-MM-dd HH:mm:ss`）：
    ///    自动补上与输入匹配的时区字段参与解析，输出仍用 `dateFormat`，避免把 UTC 当成已带标记的格式死返回原串。
    func convertUTCToLocalTime(dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String? {
        let utcDateString = self
        guard let inputZoneField = String.timeZoneField(matching: utcDateString) else {
            return utcDateString
        }
        
        // 2. 格式里已有时区字段就沿用；没有则补一个与输入匹配的
        let formatZoneField = String.trailingTimeZoneField(in: dateFormat)
        let parseFormat = formatZoneField.isEmpty ? dateFormat + inputZoneField : dateFormat
        let outputFormat = formatZoneField.isEmpty
            ? dateFormat
            : String(dateFormat.dropLast(formatZoneField.count))
        
        // 3. 解析：固定 en_US_POSIX + UTC，避免受设备区域、时区影响
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = parseFormat

        guard let date = parser.date(from: utcDateString) else {
            printError("无法解析日期字符串：\(utcDateString) / \(parseFormat)")
            return nil
        }

        // 4. 输出：仅切换时区，格式去掉时区字段，locale 保持 en_US_POSIX 保证输出格式稳定
        let outputter = DateFormatter()
        outputter.locale = Locale(identifier: "en_US_POSIX")
        outputter.timeZone = TimeZone.current
        outputter.dateFormat = outputFormat

        return outputter.string(from: date)
    }
    
    /// 当前时区时间转为utc时间
    func convertLocalTimeToUTC(dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String? {
        // 创建日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = TimeZone.current
        
        // 将字符串转换为Date对象
        guard let date = dateFormatter.date(from: self) else {
            printError("无法解析日期字符串")
            return nil
        }
        // 将时区设置为系统当前时区
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")  // 设置输入时间为UTC
//        dateFormatter.locale = Locale.current  // 使用用户当前的区域设置
        
        // 将日期转换回字符串
        let utcTimeString = dateFormatter.string(from: date)
        
        return utcTimeString
    }
    
    
    
    /// 取 `dateFormat` 末尾的时区字段（如 `Z`、`z`、`XXX`、`ZZZZZ`、`O`、`V`），不存在则返回空串
    /// 会跳过 `'...'` 引号包裹的字面量，避免把 `'Z'` 这种字面量误判为时区字段
    private static func trailingTimeZoneField(in dateFormat: String) -> String {
        let zonePatternLetters: Set<Character> = ["Z", "z", "X", "x", "O", "V", "v"]
        var inQuote = false
        var currentRun = ""
        var index = dateFormat.startIndex

        while index < dateFormat.endIndex {
            let char = dateFormat[index]
            let nextIndex = dateFormat.index(after: index)

            if char == "'" {
                // '' 表示一个字面单引号，不改变引号状态；其余 '' 成对包裹字面量
                if nextIndex < dateFormat.endIndex, dateFormat[nextIndex] == "'" {
                    currentRun = ""
                    index = dateFormat.index(after: nextIndex)
                    continue
                }
                inQuote.toggle()
                currentRun = ""
                index = nextIndex
                continue
            }

            if !inQuote {
                if char.isLetter {
                    currentRun.append(char)
                } else {
                    currentRun = ""
                }
            }
            index = nextIndex
        }

        return String(currentRun.reversed().prefix { zonePatternLetters.contains($0) }.reversed())
    }

    /// 根据日期字符串末尾的时区标记，返回可拼进 `dateFormat` 的时区字段；没有标记则返回 nil
    private static func timeZoneField(matching dateString: String) -> String? {
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasSuffix("Z") || trimmed.hasSuffix("z") {
            return "ZZZZZ"   // 支持 Z 与 ±HH:mm
        }
        if trimmed.range(of: "[+-]\\d{2}:\\d{2}$", options: .regularExpression) != nil {
            return "ZZZZZ"   // +08:00
        }
        if trimmed.range(of: "[+-]\\d{4}$", options: .regularExpression) != nil {
            return "Z"       // +0800
        }
        if trimmed.range(of: "[+-]\\d{2}$", options: .regularExpression) != nil {
            return "X"       // +08
        }
        return nil
    }
}

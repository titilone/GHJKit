//
//  GHJDateExtension.swift
//  GHJKit
//
//  Created by gaohj on 2026/11/4.
//
import Foundation

extension Date {
    
    /// 将 Date 转换为指定时区的时间字符串
    /// - Parameter format: 日期格式，默认为 "yyyy-MM-dd HH:mm:ss"
    /// - Parameter abbreviation: 时区缩写，如 "GMT+8"、"GMT-01:01"、"UTC"；
    ///   传 nil 时输出 0 时区（UTC） 的字符串；需要本地时区请用 `toLocalTimeString`
    /// - Returns: 返回指定格式、指定时区的时间字符串
    /// - Note: 固定 `en_US_POSIX`，保证输出为固定格式的 ASCII 数字、公历年份，
    ///   不受设备区域设置（佛历/回历日历、非 ASCII 数字、12 小时制偏好）影响
    ///   缩写示例：UTC+06:02，UTC+06，GMT+07，GMT+07:00
    /// - Warning: `abbreviation` 无法被识别时会静默回退为 UTC，不报错
    func toUTCString(format: String = "yyyy-MM-dd HH:mm:ss",abbreviation:String?=nil) -> String {
        printNormal("toUTCString \(format) abbreviation:\(abbreviation ?? "nil")")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        // abbreviation 为 nil 或无法识别时，统一回退到 0 时区，保证输出确定性与函数名语义一致
        formatter.timeZone = abbreviation.flatMap { TimeZone(abbreviation: $0) } ?? TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }

    /// 获取当前时区时间
    /// - Parameter format: 日期格式，默认为 "yyyy-MM-dd HH:mm:ss"
    /// - Returns: 返回指定格式、当前时区的时间字符串
    func toLocalTimeString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        return self.toUTCString(format: format, abbreviation: TimeZone.current.abbreviation())
    }
    
    // 获取Date当前时区零点时间
    var zeroClock: String {
        return self.toUTCString(format: "yyyy-MM-dd",abbreviation: TimeZone.current.abbreviation()) + " " + "00:00:00"
    }
    
    // 获取当前时区 例如: "UTC+08"
    static func utcOffsetString(minute:Bool=true)-> String {
        // 获取当前时区与UTC的秒数差
        let secondsFromGMT = TimeZone.current.secondsFromGMT()
        // 将秒数差转换为小时和分钟
        let hours = secondsFromGMT / 3600
        
        
        // 格式化字符串为"UTC±X"或"UTC±X:Y"形式
        if minute {
            let minutes = abs(secondsFromGMT % 3600) / 60
            let offsetString = String(format: "UTC%@%02d:%02d", secondsFromGMT >= 0 ? "+" : "-", abs(hours),minutes)
            return offsetString
        } else {
            let offsetString = String(format: "UTC%@%02d", secondsFromGMT >= 0 ? "+" : "-", abs(hours))
            return offsetString
        }
    }

    /// 将时间戳转换为 UTC 时间字符串
    /// - Parameters:
    ///   - timeInterval: 时间戳
    ///   - format: 日期格式
    /// - Returns: UTC 时间字符串
    /// - Note: toUTCString 的 abbreviation 缺省即 0 时区，无需再传 "GMT+00"
    static func timeIntervalToUTCString(timeInterval: TimeInterval, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        return date.toUTCString(format: format)
    }
    
    /// 将时间戳转换为 本地时区 时间字符串
    /// - Parameters:
    ///   - timeInterval: 时间戳
    ///   - format: 日期格式
    /// - Returns: 本地时区时间字符串
    /// - Note: 不经过 toUTCString（其缺省时区已是 UTC），独立使用设备当前时区输出
    static func timeIntervalToLocalTimeString(timeInterval: TimeInterval, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        return date.toUTCString(format: format, abbreviation: TimeZone.current.abbreviation())
    }
}

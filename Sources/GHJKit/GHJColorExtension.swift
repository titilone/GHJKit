//
//  GHJColorExtension.swift
//  GHJKit
//
//  Created by gaohj on 2026/11/4.
//

import Foundation

#if canImport(UIKit)
import UIKit

extension UIColor: GHJPOPCompatible {}

public extension GHJPOP where Base == UIColor {
    // MARK: 根据 十六进制字符串 获取颜色， 如："#3CB371" / "3CB371FF"
    /// 根据 十六进制字符串 获取颜色， 如："#3CB371"
    /// - Parameter hex: 十六进制字符串，支持 6 位 RGB（如 "3CB371"）与 8 位 RGBA（如 "3CB371FF"），可带 "#"/"0x" 前缀
    /// - Parameter alpha: 透明度 0-1，默认 1.0（仅 6 位格式生效；8 位格式末两位即透明度）
    /// - Returns: 返回 UIColor，格式不符时返回黑色
    /// - 用法：`UIColor.ghj.colorFromHexString("#3CB371")`
    static func colorFromHexString(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        // 清除字符串中的非十六进制字符
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        // 将十六进制字符串转换为UInt64数值
        Scanner(string: hexString).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hexString.count {
        case 6: // RGB (24-bit)
            // 通过位运算和掩码提取红、绿、蓝值
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, UInt64(alpha*255))
        case 8: // RGBA (32-bit)
            // 通过位运算和掩码提取红、绿、蓝及透明度值
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // 如果格式不符，返回一个默认颜色（黑色）
            (r, g, b, a) = (0, 0, 0, UInt64(alpha*255))
        }

        // 使用提取的RGBA值初始化UIColor，颜色值需要除以255因为UIColor使用的是0到1的范围
        let color = UIColor.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)

        return color
    }

    // MARK: 根据 十六进制数值 获取颜色， 如：0x3CB371 -> 60,179,113; 0x3CB371FF -> 60,179,113,255
    /// 根据 24 位 RGB 或 32 位 RGBA 十六进制数值获取颜色。
    /// - 24 位格式默认不透明，如：0x3CB371 -> 60,179,113
    /// - 32 位格式的最后两位表示透明度，如：0x3CB37180 -> alpha 128
    /// - Parameter hexInt: 十六进制数值，如：0x3CB371
    /// - Returns: 返回 UIColor
    /// - 用法：`UIColor.ghj.colorFromHexInt(hexInt: 0x3CB371)`
    static func colorFromHexInt(hexInt: Int) -> UIColor {
        guard let value = UInt32(exactly: hexInt) else {
            return .black
        }

        let red, green, blue, alpha: UInt32
        if value <= 0xFFFFFF {
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 0xFF
        } else {
            red = (value >> 24) & 0xFF
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        }

        return UIColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    /// 根据 RGB 值创建 UIColor（0-255 数值自动归一化）
    /// - Parameters:
    ///   - red: 红色值，0-255
    ///   - green: 绿色值，0-255
    ///   - blue: 蓝色值，0-255
    ///   - alpha: 透明度值，0-1
    /// - Returns: 返回 UIColor
    /// - 用法：`UIColor.ghj.colorWith(60, 179, 113)`
    static func colorWith(_ red: Int, _ green: Int, _ blue: Int, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }

    /// 根据 RGB 值创建 UIColor（传入 0-1 之间的 CGFloat）
    /// - Parameters:
    ///   - red: 红色值，0-1
    ///   - green: 绿色值，0-1
    ///   - blue: 蓝色值，0-1
    ///   - alpha: 透明度值，0-1
    /// - Returns: 返回 UIColor
    /// - 用法：`UIColor.ghj.colorWith(0.24, 0.70, 0.44)`
    static func colorWith(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

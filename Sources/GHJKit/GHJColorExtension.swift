//
//  File.swift
//  GHJKit
//
//  Created by gaohj on 2026/11/4.
//

import Foundation
import UIKit

public extension UIColor {
    // MARK: 根据 十六进制值 颜色获取 RGB， 如：0x3CB371 -> 60,179,113
    /// 根据 十六进制值 颜色获取 RGB， 如：0x3CB371 -> 60,179,113
    /// - Parameter hexInt: 十六进制值，如：0x3CB37
    /// - Returns: 返回 RGB
    static func colorFromHex(_ hex:String, alpha: CGFloat = 1.0) -> UIColor {
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
        
        return color;
    }
    
    // MARK: 根据 十六进制值 颜色获取 RGB或RGBA， 如：0x3CB371 -> 60,179,113; 0x3CB371FF -> 60,179,113,255;
    /// 根据 24 位 RGB 或 32 位 RGBA 十六进制值获取颜色。
    /// - 24 位格式默认不透明，如：0x3CB371 -> 60,179,113
    /// - 32 位格式的最后两位表示透明度，如：0x3CB37180 -> alpha 128
    /// - Parameter hexInt: 十六进制值，如：0x3CB37
    /// - Returns: 返回 RGB
    static func hexIntToColorRGB(hexInt: Int) -> UIColor {
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
}

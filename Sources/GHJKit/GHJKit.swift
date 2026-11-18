// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// GHJKit 对外入口
public enum GHJKit {
    /// GHJKit 资源 Bundle（图片、Asset Catalog、本地化字符串等）
    ///
    /// `Bundle.module` 由 SPM 自动生成且为 internal，外部 App 无法直接访问，
    /// 因此通过该属性对外暴露。
    public static var resourceBundle: Bundle { .module }
}

#if canImport(UIKit)
import UIKit

public extension GHJKit {
    /// 从 GHJKit 资源 Bundle 加载图片
    ///
    /// - Note: PNG 可省略扩展名；JPEG/WebP 等其他格式需写全名，如 `"bat.jpeg"`
    static func image(named name: String) -> UIImage? {
        UIImage(named: name, in: resourceBundle, compatibleWith: nil)
    }
}
#endif

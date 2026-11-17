//
//  GHJPOP.swift
//  GHJKit
//
//  Created by gaohj on 2026/11/17.
//

import Foundation

/// 命名空间包装器（参照 JKPOP / Kingfisher 的 `kf` 设计思想）
///
/// 将扩展方法收纳在 `ghj` 命名空间下，而不是直接挂在基类上：
/// 1. 不污染基类：`String` / `Date` / `UIColor` 不会多出一堆顶层方法；
/// 2. 避免命名冲突：与系统标准库、其他三方库的同名扩展互不干扰；
/// 3. 方法归属清晰：一眼能看出方法来自 GHJKit。
///
/// 用法：
/// ```swift
/// "abcdef".ghj.subString(from: 1, to: 4)          // 实例级
/// UIColor.ghj.colorFromHexString("#3CB371")       // 类型级
/// Date.ghj.timeIntervalToLocalTimeString(timeInterval: 0)
/// ```
public struct GHJPOP<Base> {
    /// 被包装的原始对象，实例方法通过它访问原值
    public let base: Base

    init(_ base: Base) {
        self.base = base
    }
}

/// 需要获得 `ghj` 命名空间能力的类型遵循此协议
/// 例如：`extension String: GHJPOPCompatible {}`
public protocol GHJPOPCompatible {}

public extension GHJPOPCompatible {
    /// 类型级命名空间入口，如：`UIColor.ghj.colorFromHexString("#FF0000")`
    static var ghj: GHJPOP<Self>.Type {
        GHJPOP<Self>.self
    }

    /// 实例级命名空间入口，如：`"hello".ghj.subString(from: 0, to: 2)`
    var ghj: GHJPOP<Self> {
        GHJPOP(self)
    }
}

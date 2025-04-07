//
//  TerminalThemeManager.swift
//  SwiftTerm
//
//  Created by 李政 on 2025/4/7.
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// 终端主题管理器，管理所有可用的主题
public class TerminalThemeManager {
    public static let shared = TerminalThemeManager()
    
    private var themes: [ThemeColor] = []
    
    private init() {
        // 注册默认主题
        registerDefaultThemes()
    }
    
    // 注册默认主题
    private func registerDefaultThemes() {
        print("TerminalThemeManager: 注册默认主题")
        
        // 添加默认主题
        registerTheme(ThemeColor.defaultDark)
        registerTheme(ThemeColor.defaultLight)
        
        // 不再需要创建redundant的主题，ViewController.initializeThemeManager会注册SettingsViewMacOs.swift中的所有主题
        
        // 打印所有已注册的主题
        print("TerminalThemeManager: 已注册主题: \(themes.map { $0.name }.joined(separator: ", "))")
    }
    
    // 注册主题
    public func registerTheme(_ theme: ThemeColor) {
        if !themes.contains(where: { $0.name == theme.name }) {
            print("TerminalThemeManager: 注册主题 '\(theme.name)'")
            themes.append(theme)
        } else {
            print("TerminalThemeManager: 主题 '\(theme.name)' 已存在，不重复注册")
        }
    }
    
    // 获取特定主题
    public func getTheme(named: String) -> ThemeColor? {
        let theme = themes.first(where: { $0.name == named })
        print("TerminalThemeManager: 查找主题 '\(named)' - \(theme != nil ? "找到" : "未找到")")
        return theme
    }
    
    // 获取默认主题
    public func getDefaultTheme() -> ThemeColor? {
        // 首先尝试获取深色/浅色主题，取决于系统设置
        #if os(iOS) || os(visionOS)
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return getTheme(named: "Default Dark") ?? themes.first
        } else {
            return getTheme(named: "Default Light") ?? themes.first
        }
        #elseif os(macOS)
        if let appearance = NSAppearance.current {
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return getTheme(named: "Default Dark") ?? themes.first
            } else {
                return getTheme(named: "Default Light") ?? themes.first
            }
        }
        #endif
        
        return themes.first
    }
    
    // 获取所有主题
    public func getAllThemes() -> [ThemeColor] {
        return themes
    }
    
    // 从字符串加载Xrdb格式主题
    public func loadThemeFromXrdb(title: String, xrdbContent: String) -> ThemeColor? {
        if let theme = ThemeColor.fromXrdb(title: title, xrdb: xrdbContent) {
            registerTheme(theme)
            return theme
        }
        return nil
    }
    
    // 从文件加载Xrdb格式主题
    public func loadThemeFromXrdbFile(title: String, path: String) -> ThemeColor? {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            return loadThemeFromXrdb(title: title, xrdbContent: content)
        } catch {
            print("加载主题文件失败: \(error)")
            return nil
        }
    }
}
#endif

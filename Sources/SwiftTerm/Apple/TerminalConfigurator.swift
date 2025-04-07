#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// 终端配置器，提供统一的接口来配置和管理 TerminalView
public class TerminalConfigurator {
    public weak var terminalView: TerminalView?
    public let containerView: TerminalContainerView
    
    public init(terminalView: TerminalView) {
        self.terminalView = terminalView
        
        // 创建容器视图
        self.containerView = terminalView.withContainer()
        
        // 立即设置容器初始背景色
        #if os(iOS) || os(visionOS)
        if let bgColor = terminalView.backgroundColor ?? terminalView.nativeBackgroundColor {
            containerView.backgroundColor = bgColor
        }
        #elseif os(macOS)
        containerView.setBackgroundColorSilently(terminalView.nativeBackgroundColor)
        #endif
        
        // 启用主题切换优化
        TerminalView.enableThemeSwitchImprovement()
    }
    
    // 应用主题
    public func applyTheme(_ theme: ThemeColor) {
        guard let terminalView = terminalView else { return }
        
        // 直接在主线程执行所有操作，避免异步问题
        DispatchQueue.main.async {
            // 创建终端主题
            let terminalTheme = TerminalView.TerminalThemeColor(
                ansiColors: theme.ansi,
                foreground: theme.foreground,
                background: theme.background,
                cursor: theme.cursor,
                selectionColor: theme.selectionColor,
                isLight: theme.background.brightness > 0.5
            )
            
            // 首先预先设置容器背景色
            #if os(iOS) || os(visionOS)
            let newBgColor = UIColor.make(color: theme.background)
            self.containerView.backgroundColor = newBgColor
            #elseif os(macOS)
            let newBgColor = NSColor.make(color: theme.background)
            self.containerView.setBackgroundColorSilently(newBgColor)
            #endif
            
            // 应用主题到终端视图
            terminalView.applyTheme(theme: terminalTheme)
            
            // 再次设置容器背景色确保一致
            #if os(iOS) || os(visionOS)
            self.containerView.backgroundColor = newBgColor
            #elseif os(macOS)
            self.containerView.setBackgroundColorSilently(newBgColor)
            #endif
            
            // 确保容器视图更新
            #if os(macOS)
            self.containerView.needsDisplay = true
            if let window = self.containerView.window {
                window.viewsNeedDisplay = true
                window.displayIfNeeded()
            }
            #endif
            
            // 保存为最后使用的主题
            UserDefaults.standard.set(theme.name, forKey: "lastTheme")
            
            // 发送通知
            NotificationCenter.default.post(
                name: Notification.Name("ThemeApplied"),
                object: self,
                userInfo: ["themeName": theme.name]
            )
        }
    }
    
    // 应用字体
    public func applyFont(name: String, size: CGFloat = 0) {
        terminalView?.changeFontSmoothly(fontName: name, size: size)
        
        // 保存字体设置
        UserDefaults.standard.set(name, forKey: "fontName")
        if size > 0 {
            UserDefaults.standard.set(Float(size), forKey: "fontSize")
        }
    }
    
    // 设置透明背景
    public func enableTransparentBackground(_ transparent: Bool) {
        guard let terminalView = terminalView else { return }
        
        if transparent {
            #if os(iOS) || os(visionOS)
            terminalView.backgroundColor = UIColor.clear
            terminalView.nativeBackgroundColor = UIColor.clear
            containerView.backgroundColor = UIColor.clear
            #elseif os(macOS)
            terminalView.nativeBackgroundColor = NSColor.clear
            containerView.backgroundColor = NSColor.clear
            #endif
        } else {
            #if os(iOS) || os(visionOS)
            containerView.syncBackgroundColor()
            #elseif os(macOS)
            containerView.syncBackgroundColor()
            #endif
        }
    }
}
#endif

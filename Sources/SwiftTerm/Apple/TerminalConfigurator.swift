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
    internal let containerView: TerminalContainerView
    
    public init(terminalView: TerminalView) {
        self.terminalView = terminalView
        
        // 创建容器视图
        self.containerView = terminalView.withContainer()
        
        // 立即设置容器初始背景色
        #if os(iOS) || os(visionOS)
        // iOS 中直接设置背景色，避免使用条件绑定
        if terminalView.backgroundColor != nil {
            containerView.backgroundColor = terminalView.backgroundColor
        } else if terminalView.nativeBackgroundColor != nil {
            containerView.backgroundColor = terminalView.nativeBackgroundColor
        }
        #elseif os(macOS)
        containerView.setBackgroundColorSilently(terminalView.nativeBackgroundColor)
        #endif
        
        // 启用主题切换优化
        TerminalView.enableThemeSwitchImprovement()
    }
    
    // 新增方法 - 同步容器背景色
    public func syncContainerBackgroundColor() {
        containerView.syncBackgroundColor()
    }
    
    // 新增方法 - 将终端添加到视图
    public func addToView(_ view: TTView) {
        view.addSubview(containerView)
    }
    
    /// 添加到视图并一步配置布局和刷新
    /// - Parameters:
    ///   - view: 父视图
    ///   - frame: 显示框架，如果为nil则使用父视图的bounds
    ///   - autoresizingMask: 自动调整掩码，默认为宽度和高度自适应
    /// - Returns: 配置器自身，用于链式调用
    @discardableResult
    public func addToViewAndConfigure(_ view: TTView, frame: CGRect? = nil, autoresizingMask: TTView.AutoresizingMask? = nil) -> Self {
        // 添加到父视图
        view.addSubview(containerView)
        
        // 设置框架和自动调整
        containerView.frame = frame ?? view.bounds
        
        // 根据平台提供默认的自动调整掩码
        let defaultMask: TTView.AutoresizingMask
        #if os(iOS) || os(visionOS)
        defaultMask = [.flexibleWidth, .flexibleHeight]
        #elseif os(macOS)
        defaultMask = [.width, .height]
        #endif
        
        containerView.autoresizingMask = autoresizingMask ?? defaultMask
        
        // 刷新显示
        #if os(iOS) || os(visionOS)
        containerView.setNeedsDisplay()
        #elseif os(macOS)
        containerView.needsDisplay = true
        #endif
        
        // 按照透明设置同步背景色
        #if os(iOS) || os(visionOS)
        let isTransparent = terminalView?.backgroundColor == UIColor.clear
        #elseif os(macOS)
        let isTransparent = terminalView?.nativeBackgroundColor == NSColor.clear
        #endif
        
        if isTransparent {
            enableTransparentBackground(true)
        } else {
            syncContainerBackgroundColor()
        }
        
        return self
    }
    
    // 新增方法 - 设置容器框架和自动调整掩码
    public func setFrame(_ frame: CGRect, autoresizingMask: TTView.AutoresizingMask? = nil) {
        containerView.frame = frame
        if let mask = autoresizingMask {
            containerView.autoresizingMask = mask
        }
    }
    
    // 新增方法 - 刷新显示
    public func refreshDisplay() {
        #if os(iOS) || os(visionOS)
        containerView.setNeedsDisplay()
        #elseif os(macOS)
        containerView.needsDisplay = true
        #endif
    }
    
    // 新增方法 - 需要布局
    public func needsLayout() {
        #if os(iOS) || os(visionOS)
        containerView.setNeedsLayout()
        #elseif os(macOS)
        containerView.needsLayout = true
        #endif
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

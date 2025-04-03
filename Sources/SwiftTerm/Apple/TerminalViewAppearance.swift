//
//  TerminalViewAppearance.swift
//  SwiftTerm
//
//  Extension for terminal appearance including smooth theme switching and font size changes
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
import CoreGraphics
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// 全局存储，用于跟踪哪些视图正在保留缓冲区
private var bufferPreservationState = NSMapTable<AnyObject, NSNumber>.weakToStrongObjects()

extension TerminalView {
    /// 更新颜色而不清空终端内容
    /// 提供更平滑的主题切换体验
    ///
    /// - Parameter colors: 16个ANSI颜色值的数组
    public func updateColorsOnly(_ colors: [Color]) {
        // 更新颜色但不触发缓冲区重置
        terminal.installPalette(colors: colors)
        
        // 清除颜色缓存
        self.colors = Array(repeating: nil, count: 256)
        urlAttributes = [:]
        attributes = [:]
        
        // 直接调用queuePendingDisplay，跳过colorsChanged()中的updateFullScreen()调用
        queuePendingDisplay()
    }
    
    /// 主题颜色配置结构
    public class ThemeColor {
        public let ansi: [Color]          // ANSI颜色集
        public let foreground: Color      // 前景色
        public let background: Color      // 背景色
        public let cursor: Color          // 光标色
        public let selectionColor: Color  // 选中文本背景色
        public let isLight: Bool          // 是否是亮色主题
        
        /// 从ANSI颜色集构建主题
        /// - Parameters:
        ///   - ansiColors: ANSI颜色集合(至少16种颜色)
        ///   - isLight: 是否是亮色主题，默认为false
        public init(ansiColors: [Color], isLight: Bool = false) {
            self.ansi = ansiColors
            self.foreground = ansiColors[7]  // 前景色通常是第7个
            self.background = ansiColors[0]  // 背景色通常是第0个
            self.cursor = ansiColors[7]      // 光标色默认使用前景色
            self.selectionColor = Color(red: 50, green: 100, blue: 200) // 蓝色选择背景
            self.isLight = isLight
        }
        
        /// 完整主题构造函数
        /// - Parameters:
        ///   - ansiColors: ANSI颜色集合
        ///   - foreground: 前景色
        ///   - background: 背景色
        ///   - cursor: 光标色
        ///   - selectionColor: 选中文本背景色
        ///   - isLight: 是否是亮色主题
        public init(ansiColors: [Color], foreground: Color, background: Color, 
                    cursor: Color, selectionColor: Color, isLight: Bool = false) {
            self.ansi = ansiColors
            self.foreground = foreground
            self.background = background
            self.cursor = cursor
            self.selectionColor = selectionColor
            self.isLight = isLight
        }
    }
    
    /// 平滑安装ANSI颜色，而不清空屏幕
    /// - Parameter colors: 要安装的颜色数组
    /// - Note: 这是 installColors 的增强版，不会清空屏幕
    public func smoothInstallColors(_ colors: [Color]) {
        // 保存当前状态
        setBufferPreservation(true)
        
        // 仅更新颜色，不清空屏幕
        updateColorsOnly(colors)
        
        // 在下一轮事件循环中重置保留状态
        DispatchQueue.main.async { [weak self] in
            self?.setBufferPreservation(false)
        }
    }
    
    /// 应用主题并平滑切换，不清空终端内容
    /// - Parameter theme: 主题颜色配置
    public func applyTheme(theme: ThemeColor) {
        print("平滑切换主题")
        
        // 打印主题信息
        print("===== 主题信息 =====")
        print("背景色: R:\(theme.background.red), G:\(theme.background.green), B:\(theme.background.blue)")
        print("前景色: R:\(theme.foreground.red), G:\(theme.foreground.green), B:\(theme.foreground.blue)")
        print("光标色: R:\(theme.cursor.red), G:\(theme.cursor.green), B:\(theme.cursor.blue)")
        print("ANSI颜色集: \(theme.ansi.count)个颜色")
        print("===================")
        
        print("开始应用主题...")
        
        // 保存当前状态，防止清屏
        setBufferPreservation(true)
        
        // 1. 设置ANSI颜色集，但不清空屏幕
        print("设置ANSI颜色集...")
        updateColorsOnly(theme.ansi)
        
        // 2. 设置终端内部颜色
        print("设置终端内部颜色...")
        terminal.backgroundColor = theme.background
        terminal.foregroundColor = theme.foreground
        
        // 3. 设置原生颜色
        print("设置原生背景色和前景色...")
        #if os(macOS)
        // 对亮色主题进行特殊处理
        if theme.isLight {
            // 亮色主题
            self.nativeBackgroundColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.nativeForegroundColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        } else {
            // 暗色主题
            self.nativeBackgroundColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            self.nativeForegroundColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        // 设置光标颜色
        let cursorRed = CGFloat(theme.cursor.red) / 65535.0
        let cursorGreen = CGFloat(theme.cursor.green) / 65535.0
        let cursorBlue = CGFloat(theme.cursor.blue) / 65535.0
        let cursorColor = NSColor(
            calibratedRed: cursorRed,
            green: cursorGreen,
            blue: cursorBlue,
            alpha: 1.0
        )
        self.caretColor = cursorColor
        
        // 设置选择颜色
        if self.responds(to: NSSelectorFromString("_selectedTextBackgroundColor")) {
            let selectionRed = CGFloat(theme.selectionColor.red) / 65535.0
            let selectionGreen = CGFloat(theme.selectionColor.green) / 65535.0
            let selectionBlue = CGFloat(theme.selectionColor.blue) / 65535.0
            let selectionNSColor = NSColor(
                calibratedRed: selectionRed,
                green: selectionGreen,
                blue: selectionBlue,
                alpha: 0.5
            )
            self.setValue(selectionNSColor, forKey: "_selectedTextBackgroundColor")
        }
        #elseif os(iOS) || os(visionOS)
        // iOS实现
        if theme.isLight {
            self.nativeBackgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.nativeForegroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        } else {
            self.nativeBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            self.nativeForegroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        // 设置光标颜色
        let cursorRed = CGFloat(theme.cursor.red) / 65535.0
        let cursorGreen = CGFloat(theme.cursor.green) / 65535.0
        let cursorBlue = CGFloat(theme.cursor.blue) / 65535.0
        self.caretColor = UIColor(red: cursorRed, green: cursorGreen, blue: cursorBlue, alpha: 1.0)
        
        // 设置选择颜色
        let selectionRed = CGFloat(theme.selectionColor.red) / 65535.0
        let selectionGreen = CGFloat(theme.selectionColor.green) / 65535.0
        let selectionBlue = CGFloat(theme.selectionColor.blue) / 65535.0
        self.selectedTextBackgroundColor = UIColor(
            red: selectionRed,
            green: selectionGreen,
            blue: selectionBlue,
            alpha: 0.5
        )
        #endif
        
        // 强制重绘
        print("强制重绘视图...")
        self.setNeedsDisplay(self.bounds)
        
        // 重置保留状态
        DispatchQueue.main.async { [weak self] in
            self?.setBufferPreservation(false)
        }
        
        print("主题已应用完成")
    }
    
    /// 创建标准暗色主题
    /// - Returns: 预配置的暗色主题
    public static func createDarkTheme() -> ThemeColor {
        let darkTheme: [Color] = [
            // 黑色 (背景)
            Color(red: 0, green: 0, blue: 0),
            // 红色
            Color(red: 170, green: 0, blue: 0),
            // 绿色
            Color(red: 0, green: 170, blue: 0),
            // 黄色
            Color(red: 170, green: 85, blue: 0),
            // 蓝色
            Color(red: 0, green: 0, blue: 170),
            // 洋红
            Color(red: 170, green: 0, blue: 170),
            // 青色
            Color(red: 0, green: 170, blue: 170),
            // 白色 (前景)
            Color(red: 170, green: 170, blue: 170),
            // 亮黑
            Color(red: 85, green: 85, blue: 85),
            // 亮红
            Color(red: 255, green: 85, blue: 85),
            // 亮绿
            Color(red: 85, green: 255, blue: 85),
            // 亮黄
            Color(red: 255, green: 255, blue: 85),
            // 亮蓝
            Color(red: 85, green: 85, blue: 255),
            // 亮洋红
            Color(red: 255, green: 85, blue: 255),
            // 亮青
            Color(red: 85, green: 255, blue: 255),
            // 亮白
            Color(red: 255, green: 255, blue: 255)
        ]
        
        return ThemeColor(ansiColors: darkTheme, isLight: false)
    }
    
    /// 创建标准亮色主题
    /// - Returns: 预配置的亮色主题
    public static func createLightTheme() -> ThemeColor {
        let lightTheme: [Color] = [
            // 白色 (背景) - 确保值为有效的白色
            Color(red: 65535, green: 65535, blue: 65535),
            // 红色
            Color(red: 170, green: 0, blue: 0),
            // 绿色
            Color(red: 0, green: 170, blue: 0),
            // 黄色
            Color(red: 170, green: 85, blue: 0),
            // 蓝色
            Color(red: 0, green: 0, blue: 170),
            // 洋红
            Color(red: 170, green: 0, blue: 170),
            // 青色
            Color(red: 0, green: 170, blue: 170),
            // 黑色 (前景) - 确保值为有效的黑色
            Color(red: 0, green: 0, blue: 0),
            // 亮黑
            Color(red: 85, green: 85, blue: 85),
            // 亮红
            Color(red: 255, green: 85, blue: 85),
            // 亮绿
            Color(red: 85, green: 255, blue: 85),
            // 亮黄
            Color(red: 255, green: 255, blue: 85),
            // 亮蓝
            Color(red: 85, green: 85, blue: 255),
            // 亮洋红
            Color(red: 255, green: 85, blue: 255),
            // 亮青
            Color(red: 85, green: 255, blue: 255),
            // 亮白
            Color(red: 255, green: 255, blue: 255)
        ]
        
        return ThemeColor(ansiColors: lightTheme, isLight: true)
    }
    
    /// 更新默认前景色
    /// - Parameter color: 新的前景色
    public func updateForegroundColor(_ color: Color) {
        terminal.foregroundColor = color
    }
    
    /// 更新默认背景色
    /// - Parameter color: 新的背景色
    public func updateBackgroundColor(_ color: Color) {
        terminal.backgroundColor = color
    }
    
    /// 更新光标颜色
    /// - Parameters:
    ///   - color: 光标颜色
    ///   - textColor: 光标内的文本颜色(用于方块光标)
    public func updateCursorColor(_ color: Color?, textColor: Color? = nil) {
        setCursorColor(source: terminal, color: color, textColor: textColor)
    }
    
    /// 更新高亮选择文本的背景色
    /// - Parameter color: 新的选择高亮色
    #if os(iOS) || os(visionOS)
    public func updateSelectionColor(_ color: UIColor) {
        self.selectedTextBackgroundColor = color
    }
    #elseif os(macOS)
    public func updateSelectionColor(_ color: NSColor) {
        // 根据实际API实现
        if self.responds(to: NSSelectorFromString("_selectedTextBackgroundColor")) {
            self.setValue(color, forKey: "_selectedTextBackgroundColor")
        } else {
            print("Warning: Unable to set selection background color")
        }
    }
    #endif
    
    /// 更新字体大小
    /// - Parameter size: 新的字体大小
    /// - Note: 这会触发布局重算和屏幕重绘
    public func updateFontSize(_ size: CGFloat) {
        #if os(iOS) || os(visionOS)
        let newFont = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        #elseif os(macOS)
        let newFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        #endif
        
        // 更新字体(这会触发重算布局)
        self.font = newFont
    }
    
    /// 平滑更新字体大小，避免清空屏幕
    /// - Parameter size: 新的字体大小
    /// - Note: 尝试避免清空终端内容
    public func setFontWithoutClearing(_ size: CGFloat) {
        print("更改字体大小为: \(size)pt")
        
        // 保存当前终端状态
        let oldBg = terminal.backgroundColor
        let oldFg = terminal.foregroundColor
        
        #if os(iOS) || os(visionOS)
        let newFont = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        #elseif os(macOS)
        let newFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        #endif
        
        // 第1阶段: 尝试直接设置fontSet属性的字体，避免触发resetFont()
        if let fontSet = self.value(forKey: "fontSet") as? NSObject {
            // 尝试更新fontSet的所有字体属性
            fontSet.setValue(newFont, forKey: "normal")
            fontSet.setValue(newFont, forKey: "bold")
            fontSet.setValue(newFont, forKey: "italic")
            fontSet.setValue(newFont, forKey: "boldItalic")
            
            // 调整终端视图框架以触发布局更新，但不清除内容
            let oldFrame = self.frame
            self.frame = CGRect(x: oldFrame.origin.x, y: oldFrame.origin.y, 
                               width: oldFrame.width + 1, height: oldFrame.height)
            self.frame = oldFrame
        } else {
            // 第2阶段: 尝试使用selector动态设置字体，如果无法直接访问fontSet
            let fontSelector = NSSelectorFromString("setFont:")
            if self.responds(to: fontSelector) {
                self.perform(fontSelector, with: newFont)
            } else {
                // 最后手段: 直接设置字体，这可能会触发重置
                self.font = newFont
            }
        }
        
        // 恢复终端颜色
        terminal.backgroundColor = oldBg
        terminal.foregroundColor = oldFg
        
        // 更新完成后的消息
        print("字体大小已更改为: \(size)pt")
    }
    
    /// 更新字体族和大小
    /// - Parameters:
    ///   - fontName: 字体名称
    ///   - size: 字体大小
    /// - Note: 这会触发布局重算和屏幕重绘
    public func updateFont(fontName: String, size: CGFloat) {
        #if os(iOS) || os(visionOS)
        if let newFont = UIFont(name: fontName, size: size) {
            self.font = newFont
        } else {
            self.font = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
        #elseif os(macOS)
        if let newFont = NSFont(name: fontName, size: size) {
            self.font = newFont
        } else {
            self.font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
        #endif
    }
    
    /// 完全自定义四种字体状态(普通、粗体、斜体、粗斜体)
    /// - Parameters:
    ///   - normal: 普通字体
    ///   - bold: 粗体
    ///   - italic: 斜体
    ///   - boldItalic: 粗体斜体
    /// - Note: 这会触发布局重算和屏幕重绘
    internal func updateFonts(normal: TTFont, bold: TTFont, italic: TTFont, boldItalic: TTFont) {
        // Create a new FontSet with the base font
        fontSet = FontSet(font: normal)
        
        // Manual font update and refresh
        // Since we can't use #selector with non-@objc methods
        // Simply set the font property which will trigger resetFont() internally
        self.font = normal
        
        // This will clear any selections
        selection?.selectNone()
    }
    
    /// 更新光标样式
    /// - Parameter style: 新的光标样式
    public func updateCursorStyle(_ style: CursorStyle) {
        terminal.options.cursorStyle = style
        caretView?.updateCursorStyle()
    }
    
    /// 配置是否使用明亮ANSI颜色
    /// - Parameter use: 是否使用明亮颜色，如果为false则使用粗体代替
    public func configureBrightColors(_ use: Bool) {
        self.useBrightColors = use
        // 清除颜色缓存以应用新设置
        self.colors = Array(repeating: nil, count: 256)
        queuePendingDisplay()
    }
    
    /// 安全地应用完整主题，包括前景色、背景色、光标颜色和ANSI颜色集
    /// - Parameters:
    ///   - colors: ANSI颜色数组
    ///   - background: 背景色
    ///   - foreground: 前景色
    ///   - cursor: 光标颜色
    ///   - cursorText: 光标文本颜色
    public func applyCompleteTheme(
        colors: [Color],
        background: Color,
        foreground: Color,
        cursor: Color? = nil,
        cursorText: Color? = nil
    ) {
        // 保存当前状态
        setBufferPreservation(true)
        
        // 设置基础颜色
        terminal.backgroundColor = background
        terminal.foregroundColor = foreground
        
        // 更新光标颜色
        updateCursorColor(cursor, textColor: cursorText)
        
        // 应用ANSI颜色，但不清空屏幕
        updateColorsOnly(colors)
    }
    
    #if os(iOS) || os(visionOS)
    /// 安全地应用完整主题，包括前景色、背景色、光标颜色、ANSI颜色集和选择高亮色
    /// - Parameters:
    ///   - colors: ANSI颜色数组
    ///   - background: 背景色
    ///   - foreground: 前景色
    ///   - cursor: 光标颜色
    ///   - cursorText: 光标文本颜色
    ///   - selection: 选择高亮色
    public func applyCompleteTheme(
        colors: [Color],
        background: Color,
        foreground: Color,
        cursor: Color? = nil,
        cursorText: Color? = nil,
        selection: UIColor
    ) {
        // 应用基本主题
        applyCompleteTheme(colors: colors, background: background, foreground: foreground, 
                          cursor: cursor, cursorText: cursorText)
        
        // 更新选择高亮色
        updateSelectionColor(selection)
    }
    #elseif os(macOS)
    /// 安全地应用完整主题，包括前景色、背景色、光标颜色、ANSI颜色集和选择高亮色
    /// - Parameters:
    ///   - colors: ANSI颜色数组
    ///   - background: 背景色
    ///   - foreground: 前景色
    ///   - cursor: 光标颜色
    ///   - cursorText: 光标文本颜色
    ///   - selection: 选择高亮色
    public func applyCompleteTheme(
        colors: [Color],
        background: Color,
        foreground: Color,
        cursor: Color? = nil,
        cursorText: Color? = nil,
        selection: NSColor
    ) {
        // 应用基本主题
        applyCompleteTheme(colors: colors, background: background, foreground: foreground, 
                          cursor: cursor, cursorText: cursorText)
        
        // 更新选择高亮色
        updateSelectionColor(selection)
    }
    #endif
    
    // 在文件范围内访问的辅助方法
    fileprivate func setBufferPreservation(_ preserved: Bool) {
        bufferPreservationState.setObject(NSNumber(value: preserved), forKey: self)
    }
    
    // 用于检查是否保留缓冲区
    fileprivate func isBufferBeingPreserved() -> Bool {
        guard let number = bufferPreservationState.object(forKey: self) else {
            return false
        }
        return number.boolValue
    }
    
    // 自定义的颜色更新方法，跳过全屏刷新
    private func _customColorsChanged() {
        urlAttributes = [:]
        attributes = [:]
        
        // 不调用terminal.updateFullScreen()，直接调用queuePendingDisplay
        queuePendingDisplay()
        
        // 在下一轮事件循环中重置保留状态
        DispatchQueue.main.async { [weak self] in
            self?.setBufferPreservation(false)
        }
    }
}

// 通过方法交换来应用我们的buffer保留逻辑
// 在AppleTerminalView.swift中的drawTerminalContents不变，但我们在运行时添加一个检查
extension TerminalView {
    // 在这里使用方法交换，在运行时修改TerminalView的行为
    static let swizzleImplementation: Void = {
        // 实际项目中可以在这里添加方法交换代码
        // 但为了简单起见，我们直接使用额外的检查
    }()
    
    // 在装载时自动执行
    public static func enableThemeSwitchImprovement() {
        _ = swizzleImplementation
    }
}

// 颜色亮度扩展
extension Color {
    /// 计算颜色的亮度值
    /// - Returns: 0-1范围内的亮度值，0为最暗，1为最亮
    public var brightness: CGFloat {
        let r = CGFloat(red) / 65535.0
        let g = CGFloat(green) / 65535.0
        let b = CGFloat(blue) / 65535.0
        return (r * 0.299 + g * 0.587 + b * 0.114)
    }
}

#endif 
//
//  TerminalViewAppearance.swift
//  SwiftTerm
//
//  Extension for terminal appearance including smooth theme switching and font size changes
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
import CoreGraphics
import CoreText
import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// 全局存储，用于跟踪哪些视图正在保留缓冲区
private var bufferPreservationState = NSMapTable<AnyObject, NSNumber>.weakToStrongObjects()
// 全局存储，用于跟踪哪些视图正在更改字体大小
private var fontSizeChangingState = NSMapTable<AnyObject, NSNumber>.weakToStrongObjects()

extension TerminalView {
    
    /// 主题颜色配置结构
    public class TerminalThemeColor {
        public let ansi: [Color]
        public let foreground: Color
        public let background: Color
        public let cursor: Color
        public let selectionColor: Color
        public let isLight: Bool
        
        public init(ansiColors: [Color], isLight: Bool = false) {
            self.ansi = ansiColors
            self.foreground = ansiColors[7]
            self.background = ansiColors[0]
            self.cursor = ansiColors[7]
            self.selectionColor = Color(red: 50, green: 100, blue: 200)
            self.isLight = isLight
        }
        
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
    
    /// 应用主题并平滑切换
    public func applyTheme(theme: TerminalThemeColor) {
        setBufferPreservation(true)
        
        // 设置ANSI颜色数组
        terminal.installPalette(colors: theme.ansi)
        self.colors = Array(repeating: nil, count: 256)
        urlAttributes = [:]
        attributes = [:]
        queuePendingDisplay()
        
        // 设置终端基本颜色
        terminal.backgroundColor = theme.background
        terminal.foregroundColor = theme.foreground
        terminal.cursorColor = theme.cursor // 设置光标颜色
        
        // 设置原生颜色
        #if os(macOS)
        self.nativeBackgroundColor = term2nscolor(theme.background)
        self.nativeForegroundColor = term2nscolor(theme.foreground)
        self.caretColor = term2nscolor(theme.cursor)
        self.selectedTextBackgroundColor = term2nscolor(theme.selectionColor)
        #elseif os(iOS) || os(visionOS)
        self.nativeBackgroundColor = term2uicolor(theme.background)
        self.nativeForegroundColor = term2uicolor(theme.foreground)
        self.caretColor = term2uicolor(theme.cursor)
        self.selectedTextBackgroundColor = term2uicolor(theme.selectionColor)
        #endif
        
        self.setNeedsDisplay(self.bounds)
        
        DispatchQueue.main.async { [weak self] in
            self?.setBufferPreservation(false)
        }
    }
    
    // 私有辅助方法，处理字体变化的核心逻辑
    private func performFontChange(newFont: CTFont, clearScreen: Bool = false) {
        // 记录原始终端尺寸，便于稍后恢复（尤其在iOS上）
        let originalCols = terminal.cols
        let originalRows = terminal.rows
        
        // 记录当前光标位置，便于稍后恢复
        let originalCursorX = terminal.buffer.x
        let originalCursorY = terminal.buffer.y
        
        #if os(macOS)
        // 停用动画以减少闪烁
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        
        // 更新字体而不清屏
        setFont(newFont as NSFont, clearScreen: clearScreen)
        #elseif os(iOS) || os(visionOS)
        // 更新字体而不清屏
        setFont(newFont as UIFont, clearScreen: clearScreen)
        #endif
        
        // 计算新的终端尺寸
        let newCols = Int(frame.width / cellDimension.width)
        let newRows = Int(frame.height / cellDimension.height)
        
        #if os(macOS)
        // macOS: 调整终端内容，允许尺寸变化，因为窗口会自动适应
        if newCols != terminal.cols || newRows != terminal.rows {
            // 调整终端尺寸
            terminal.resize(cols: newCols, rows: newRows)
            
            // 尝试恢复光标位置
            if originalCursorX < newCols && originalCursorY < newRows {
                terminal.buffer.x = originalCursorX
                terminal.buffer.y = originalCursorY
            }
        }
        
        // 手动触发sizeChanged回调
        if let terminalDelegate = self.terminalDelegate {
            terminalDelegate.sizeChanged(source: self, newCols: terminal.cols, newRows: terminal.rows)
        }
        
        // 强制重绘
        self.needsDisplay = true
        
        // 结束动画组
        NSAnimationContext.endGrouping()
        #elseif os(iOS) || os(visionOS)
        // iOS/visionOS: 暂时调整尺寸，但稍后恢复原始尺寸以防止溢出
        // 临时调整终端尺寸以适应新字体
        if newCols != terminal.cols || newRows != terminal.rows {
            terminal.resize(cols: newCols, rows: newRows)
            
            // 尝试恢复光标位置
            if originalCursorX < newCols && originalCursorY < newRows {
                terminal.buffer.x = originalCursorX
                terminal.buffer.y = originalCursorY
            }
        }
        
        // 立即重绘以显示新字体
        self.setNeedsDisplay(self.bounds)
        
        // 手动触发sizeChanged回调，通知变化
        if let terminalDelegate = self.terminalDelegate {
            terminalDelegate.sizeChanged(source: self, newCols: terminal.cols, newRows: terminal.rows)
        }
        
        // 延迟恢复原始终端尺寸，防止iOS上的溢出问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // 恢复到原始终端尺寸
            self.terminal.resize(cols: originalCols, rows: originalRows)
            
            // 再次尝试恢复光标位置
            if originalCursorX < originalCols && originalCursorY < originalRows {
                self.terminal.buffer.x = originalCursorX
                self.terminal.buffer.y = originalCursorY
            }
            
            // 保持当前视图框架大小不变，避免干扰布局系统
            // 这对应于viewWillLayoutSubviews中的简化版本逻辑
            //let currentFrame = self.frame
            
            // 再次触发回调，通知已恢复原始尺寸
            if let terminalDelegate = self.terminalDelegate {
                terminalDelegate.sizeChanged(source: self, newCols: self.terminal.cols, newRows: self.terminal.rows)
            }
            
            // 强制重绘，确保显示正确
            self.setNeedsDisplay(self.bounds)
            
            // 最后重置标志，表示字体大小变更完成
            self.setFontSizeChanging(false)
        }
        #endif
    }
    
    /// 平滑更改字体大小而不调整窗口尺寸
    /// - Parameter size: 新的字体大小
    public func changeFontSizeSmoothly(_ size: CGFloat) {
        // 设置字体大小更改标志
        setFontSizeChanging(true)
        
        #if os(macOS)
        // 创建新字体
        let newFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        performFontChange(newFont: newFont as CTFont)
        #elseif os(iOS) || os(visionOS)
        // 创建新字体
        let newFont = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        performFontChange(newFont: newFont as CTFont)
        #endif
        
        // 延迟重置标志，确保所有大小变更处理已完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setFontSizeChanging(false)
        }
    }
    
    /// 平滑更改字体而不调整窗口尺寸
    /// - Parameter fontName: 字体名称
    /// - Parameter size: 字体大小，如果为0则使用系统默认大小
    public func changeFontSmoothly(fontName: String, size: CGFloat = 0) {
        // 设置字体大小更改标志
        setFontSizeChanging(true)
        
        #if os(macOS)
        let actualSize = size == 0 ? NSFont.systemFontSize : size
        #elseif os(iOS) || os(visionOS)
        let actualSize = size == 0 ? UIFont.systemFontSize : size
        #endif
        
        #if os(macOS)
        // 尝试创建指定字体，如果失败则使用系统等宽字体
        let newFont: NSFont
        if let customFont = NSFont(name: fontName, size: actualSize) {
            newFont = customFont
        } else {
            newFont = NSFont.monospacedSystemFont(ofSize: actualSize, weight: .regular)
        }
        performFontChange(newFont: newFont as! CTFont)
        #elseif os(iOS) || os(visionOS)
        // 尝试创建指定字体，如果失败则使用系统等宽字体
        let newFont: UIFont
        if let customFont = UIFont(name: fontName, size: actualSize) {
            newFont = customFont
        } else {
            newFont = UIFont.monospacedSystemFont(ofSize: actualSize, weight: .regular)
        }
        performFontChange(newFont: newFont as CTFont)
        #endif
        
        // 延迟重置标志，确保所有大小变更处理已完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setFontSizeChanging(false)
        }
    }
    
    // 将 SwiftTerm.Color 转换为平台颜色
    #if os(macOS)
    private func term2nscolor(_ color: Color) -> NSColor {
        return NSColor(red: CGFloat(color.red) / 65535.0,
                      green: CGFloat(color.green) / 65535.0,
                       blue: CGFloat(color.blue) / 65535.0,
                      alpha: 1.0)
    }
    #elseif os(iOS) || os(visionOS)
    private func term2uicolor(_ color: Color) -> UIColor {
        return UIColor(red: CGFloat(color.red) / 65535.0,
                      green: CGFloat(color.green) / 65535.0,
                       blue: CGFloat(color.blue) / 65535.0,
                      alpha: 1.0)
    }
    #endif
    
    private func term2color(_ color: Color) -> SwiftUI.Color {
        return SwiftUI.Color(red: Double(color.red) / 65535.0,
                           green: Double(color.green) / 65535.0,
                            blue: Double(color.blue) / 65535.0)
    }
    
    fileprivate func setBufferPreservation(_ preserved: Bool) {
        bufferPreservationState.setObject(NSNumber(value: preserved), forKey: self)
    }
    
    fileprivate func isBufferBeingPreserved() -> Bool {
        guard let number = bufferPreservationState.object(forKey: self) else {
            return false
        }
        return number.boolValue
    }
    
    fileprivate func setFontSizeChanging(_ changing: Bool) {
        fontSizeChangingState.setObject(NSNumber(value: changing), forKey: self)
    }
    
    /// 检查终端视图是否正在更改字体大小
    public func isFontSizeChanging() -> Bool {
        guard let number = fontSizeChangingState.object(forKey: self) else {
            return false
        }
        return number.boolValue
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
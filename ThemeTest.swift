import Foundation
import SwiftTerm

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// 创建一个示例终端颜色主题
let darkTheme: [SwiftTerm.Color] = [
    // 黑色 (背景)
    SwiftTerm.Color(red: 0, green: 0, blue: 0),
    // 红色
    SwiftTerm.Color(red: 170, green: 0, blue: 0),
    // 绿色
    SwiftTerm.Color(red: 0, green: 170, blue: 0),
    // 黄色
    SwiftTerm.Color(red: 170, green: 85, blue: 0),
    // 蓝色
    SwiftTerm.Color(red: 0, green: 0, blue: 170),
    // 洋红
    SwiftTerm.Color(red: 170, green: 0, blue: 170),
    // 青色
    SwiftTerm.Color(red: 0, green: 170, blue: 170),
    // 白色 (前景)
    SwiftTerm.Color(red: 170, green: 170, blue: 170),
    // 亮黑
    SwiftTerm.Color(red: 85, green: 85, blue: 85),
    // 亮红
    SwiftTerm.Color(red: 255, green: 85, blue: 85),
    // 亮绿
    SwiftTerm.Color(red: 85, green: 255, blue: 85),
    // 亮黄
    SwiftTerm.Color(red: 255, green: 255, blue: 85),
    // 亮蓝
    SwiftTerm.Color(red: 85, green: 85, blue: 255),
    // 亮洋红
    SwiftTerm.Color(red: 255, green: 85, blue: 255),
    // 亮青
    SwiftTerm.Color(red: 85, green: 255, blue: 255),
    // 亮白
    SwiftTerm.Color(red: 255, green: 255, blue: 255),
]

let lightTheme: [SwiftTerm.Color] = [
    // 白色 (背景)
    SwiftTerm.Color(red: 255, green: 255, blue: 255),
    // 红色
    SwiftTerm.Color(red: 170, green: 0, blue: 0),
    // 绿色
    SwiftTerm.Color(red: 0, green: 170, blue: 0),
    // 黄色
    SwiftTerm.Color(red: 170, green: 85, blue: 0),
    // 蓝色
    SwiftTerm.Color(red: 0, green: 0, blue: 170),
    // 洋红
    SwiftTerm.Color(red: 170, green: 0, blue: 170),
    // 青色
    SwiftTerm.Color(red: 0, green: 170, blue: 170),
    // 黑色 (前景)
    SwiftTerm.Color(red: 0, green: 0, blue: 0),
    // 亮黑
    SwiftTerm.Color(red: 85, green: 85, blue: 85),
    // 亮红
    SwiftTerm.Color(red: 255, green: 85, blue: 85),
    // 亮绿
    SwiftTerm.Color(red: 85, green: 255, blue: 85),
    // 亮黄
    SwiftTerm.Color(red: 255, green: 255, blue: 85),
    // 亮蓝
    SwiftTerm.Color(red: 85, green: 85, blue: 255),
    // 亮洋红
    SwiftTerm.Color(red: 255, green: 85, blue: 255),
    // 亮青
    SwiftTerm.Color(red: 85, green: 255, blue: 255),
    // 亮白
    SwiftTerm.Color(red: 255, green: 255, blue: 255),
]

print("示例代码：在您的项目中可以这样使用主题切换功能")
print("====================================================")
print("// 1. 使用updateColorsOnly平滑切换到暗色主题")
print("terminalView.updateColorsOnly(darkTheme)")
print("")
print("// 2. 使用updateColorsOnly平滑切换到亮色主题")
print("terminalView.updateColorsOnly(lightTheme)")
print("")
print("// 3. 单独更新前景色")
print("// 亮绿色")
print("terminalView.updateForegroundColor(SwiftTerm.Color(red: 85, green: 255, blue: 85))")
print("")
print("// 4. 单独更新背景色")
print("// 黑色")
print("terminalView.updateBackgroundColor(SwiftTerm.Color(red: 0, green: 0, blue: 0))")
print("")
print("// 5. 更新光标颜色")
print("let yellow = SwiftTerm.Color(red: 170, green: 85, blue: 0)")
print("let black = SwiftTerm.Color(red: 0, green: 0, blue: 0)")
print("terminalView.updateCursorColor(yellow, textColor: black)")
print("")
print("// 6. 更新选择文本的高亮颜色")
print("#if os(macOS)")
print("terminalView.updateSelectionColor(NSColor.blue.withAlphaComponent(0.5))")
print("#else")
print("terminalView.updateSelectionColor(UIColor.blue.withAlphaComponent(0.5))")
print("#endif")
print("")
print("// 7. 更新字体大小")
print("terminalView.updateFontSize(14)")
print("")

print("主要优点：")
print("1. 使用updateColorsOnly可以平滑切换主题，不会清空终端内容")
print("2. 可以单独更新各个UI元素，而不触发整个屏幕重绘")
print("3. 提供了更细粒度的控制，允许单独更新字体、颜色等属性") 
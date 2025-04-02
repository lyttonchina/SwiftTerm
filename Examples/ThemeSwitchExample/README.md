# SwiftTerm 主题切换功能

这个功能增强了 SwiftTerm 库，允许在不清空终端内容的情况下平滑切换主题。

## 主要功能

- `updateColorsOnly(colors)`: 平滑更新终端颜色，不会清空屏幕内容
- 单独更新各个UI元素的方法，包括前景色、背景色、光标颜色等
- 更细粒度的控制，允许单独更新字体、颜色等属性

## 如何测试

1. 编译 SwiftTerm 库
   ```bash
   cd /Volumes/data/swift/SwiftTerm
   swift build
   ```

2. 运行测试程序
   ```bash
   swift run ThemeSwitchExample
   ```
   
   或者，您可以使用 Xcode 打开项目并运行测试程序：
   ```bash
   cd /Volumes/data/swift/SwiftTerm
   swift package generate-xcodeproj
   open SwiftTerm.xcodeproj
   ```

3. 在测试应用中，使用窗口顶部菜单切换主题：
   - 使用 `主题 > 暗色主题` 切换到暗色主题（快捷键: ⌘D）
   - 使用 `主题 > 亮色主题` 切换到亮色主题（快捷键: ⌘L）
   - 使用 `主题 > 传统方式切换主题` 观察传统方式下的闪烁（快捷键: ⌘T）

4. 对比新旧方法的区别：
   - 新方法 `updateColorsOnly()`: 切换颜色不会清空终端内容，平滑过渡
   - 旧方法 `installColors()`: 会先清空屏幕再重绘，导致闪烁

## 在您自己的项目中使用

假设您在项目中使用 SwiftTerm 的 TerminalView：

```swift
// 定义颜色主题（16个ANSI颜色）
let darkTheme: [SwiftTerm.Color] = [
    // 黑色 (背景)
    SwiftTerm.Color(red: 0, green: 0, blue: 0),
    // 红色
    SwiftTerm.Color(red: 170, green: 0, blue: 0),
    // 绿色
    SwiftTerm.Color(red: 0, green: 170, blue: 0),
    // 其他颜色...
]

// 首先启用主题切换优化
TerminalView.enableThemeSwitchImprovement()

// 然后在需要切换主题时使用 updateColorsOnly
// 而不是 installColors
terminalView.updateColorsOnly(darkTheme) // 不会清空终端内容

// 您也可以单独更新各个元素
terminalView.updateForegroundColor(SwiftTerm.Color(red: 85, green: 255, blue: 85)) // 亮绿色
terminalView.updateBackgroundColor(SwiftTerm.Color(red: 0, green: 0, blue: 0)) // 黑色
terminalView.updateCursorColor(SwiftTerm.Color(red: 170, green: 85, blue: 0)) // 黄色
terminalView.updateFontSize(14)
```

## 技术说明

此优化通过以下方式实现：

1. 跳过 `colorsChanged()` 中的 `terminal.updateFullScreen()` 调用
2. 直接更新颜色缓存并调用 `queuePendingDisplay()`
3. 这样保留了终端缓冲区的内容，同时仍然应用了新的颜色

## 问题反馈

如果您在使用过程中遇到任何问题，请提交 issue 到 GitHub 仓库。 
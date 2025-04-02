import Foundation
import SwiftTerm

#if os(macOS)
import AppKit

class ThemeSwitchExample: NSObject, TerminalViewDelegate {
    var window: NSWindow!
    var terminalView: TerminalView!
    var shell: LocalProcess!
    
    // 定义主题
    let darkTheme: [Color] = [
        Color.black,       // 黑色 (背景)
        Color.red,         // 红色
        Color.green,       // 绿色
        Color.yellow,      // 黄色
        Color.blue,        // 蓝色
        Color.magenta,     // 洋红
        Color.cyan,        // 青色
        Color.white,       // 白色 (前景)
        Color.brightBlack, // 亮黑
        Color.brightRed,   // 亮红
        Color.brightGreen, // 亮绿
        Color.brightYellow,// 亮黄
        Color.brightBlue,  // 亮蓝
        Color.brightMagenta,// 亮洋红
        Color.brightCyan,  // 亮青
        Color.brightWhite  // 亮白
    ]
    
    let lightTheme: [Color] = [
        Color.white,       // 白色 (背景)
        Color.red,         // 红色
        Color.green,       // 绿色
        Color.yellow,      // 黄色
        Color.blue,        // 蓝色
        Color.magenta,     // 洋红
        Color.cyan,        // 青色
        Color.black,       // 黑色 (前景)
        Color.brightBlack, // 亮黑
        Color.brightRed,   // 亮红
        Color.brightGreen, // 亮绿
        Color.brightYellow,// 亮黄
        Color.brightBlue,  // 亮蓝
        Color.brightMagenta,// 亮洋红
        Color.brightCyan,  // 亮青
        Color.brightWhite  // 亮白
    ]
    
    func setup() {
        // 创建窗口
        let rect = NSRect(x: 100, y: 100, width: 800, height: 600)
        window = NSWindow(contentRect: rect, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "SwiftTerm 主题切换测试"
        
        // 创建终端视图
        terminalView = TerminalView(frame: rect)
        terminalView.terminalDelegate = self
        
        // 启用主题切换优化
        TerminalView.enableThemeSwitchImprovement()
        
        // 设置菜单
        setupMenu()
        
        // 添加到窗口
        window.contentView?.addSubview(terminalView)
        
        // 启动shell
        shell = LocalProcess(executable: "/bin/bash", args: ["-l"])
        shell.startProcess()
        
        // 启动终端
        terminalView.startProcess(shell: shell)
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        
        print("请使用窗口顶部菜单切换主题")
        print("观察终端内容在切换主题时是否保持不变")
    }
    
    func setupMenu() {
        let mainMenu = NSMenu(title: "主菜单")
        
        // 主题菜单
        let themeMenu = NSMenu(title: "主题")
        let themeMenuItem = NSMenuItem(title: "主题", action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeMenu
        
        // 暗色主题
        let darkThemeItem = NSMenuItem(title: "暗色主题", action: #selector(switchToDarkTheme), keyEquivalent: "d")
        themeMenu.addItem(darkThemeItem)
        
        // 亮色主题
        let lightThemeItem = NSMenuItem(title: "亮色主题", action: #selector(switchToLightTheme), keyEquivalent: "l")
        themeMenu.addItem(lightThemeItem)
        
        // 传统方式切换主题
        themeMenu.addItem(NSMenuItem.separator())
        let traditionalThemeItem = NSMenuItem(title: "传统方式切换主题(会闪烁)", action: #selector(switchThemeTraditional), keyEquivalent: "t")
        themeMenu.addItem(traditionalThemeItem)
        
        // 添加分隔符
        themeMenu.addItem(NSMenuItem.separator())
        
        // 更新光标颜色
        let cursorMenuItem = NSMenuItem(title: "更新光标颜色", action: #selector(updateCursorColor), keyEquivalent: "c")
        themeMenu.addItem(cursorMenuItem)
        
        // 更新选择高亮色
        let selectionMenuItem = NSMenuItem(title: "更新选择高亮色", action: #selector(updateSelectionColor), keyEquivalent: "s")
        themeMenu.addItem(selectionMenuItem)
        
        // 更新字体
        let fontMenuItem = NSMenuItem(title: "更新字体大小", action: #selector(updateFontSize), keyEquivalent: "f")
        themeMenu.addItem(fontMenuItem)
        
        // 添加主题菜单到主菜单
        mainMenu.addItem(themeMenuItem)
        
        // 设置应用菜单
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc func switchToDarkTheme() {
        print("平滑切换到暗色主题")
        terminalView.updateColorsOnly(darkTheme)
    }
    
    @objc func switchToLightTheme() {
        print("平滑切换到亮色主题")
        terminalView.updateColorsOnly(lightTheme)
    }
    
    @objc func switchThemeTraditional() {
        print("使用传统方式切换主题（会看到闪烁）")
        if terminalView.nativeBackgroundColor.brightnessComponent > 0.5 {
            terminalView.installColors(darkTheme)
        } else {
            terminalView.installColors(lightTheme)
        }
    }
    
    @objc func updateCursorColor() {
        print("更新光标颜色")
        terminalView.updateCursorColor(Color.yellow, textColor: Color.black)
    }
    
    @objc func updateSelectionColor() {
        print("更新选择高亮色")
        terminalView.updateSelectionColor(NSColor.blue.withAlphaComponent(0.5))
    }
    
    @objc func updateFontSize() {
        print("更新字体大小")
        terminalView.updateFontSize(16)
    }
    
    // MARK: - TerminalViewDelegate
    
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        shell.resize(cols: newCols, rows: newRows)
    }
    
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        shell.send(data: data)
    }
    
    func scrolled(source: TerminalView, position: Double) {
        // 不需要实现
    }
    
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        // 不需要实现
    }
    
    func setTerminalTitle(source: TerminalView, title: String) {
        window.title = title
    }
    
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        // 终端进程结束，可以关闭窗口或重启进程
        print("进程已终止，退出代码: \(exitCode ?? -1)")
    }
}

// 主程序入口
class AppDelegate: NSObject, NSApplicationDelegate {
    var example: ThemeSwitchExample!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        example = ThemeSwitchExample()
        example.setup()
    }
}

// 启动应用
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

#else 
// iOS/visionOS版本略
print("请使用macOS版本运行此示例")
#endif 
import Foundation
import SwiftTerm
import Darwin

#if os(macOS)
import AppKit

class ThemeSwitchExample: NSObject, TerminalViewDelegate, LocalProcessDelegate {
    var window: NSWindow!
    var terminalView: TerminalView!
    var shell: LocalProcess!
    
    // 定义主题
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
        shell = LocalProcess(delegate: self)
        shell.startProcess()
        
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
        let yellow = SwiftTerm.Color(red: 170, green: 85, blue: 0)
        let black = SwiftTerm.Color(red: 0, green: 0, blue: 0)
        terminalView.updateCursorColor(yellow, textColor: black)
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
        // 当终端大小变化时，更新终端尺寸
        var size = getWindowSize()
        size.ws_row = UInt16(newRows)
        size.ws_col = UInt16(newCols)
        
        // 将更新后的尺寸应用到ioctl
        let fd = shell.childfd
        _ = ioctl(fd, TIOCSWINSZ, ioctl(fd, TIOCSWINSZ, &size)size)
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
    
    // MARK: - LocalProcessDelegate
    
    func dataReceived(slice: ArraySlice<UInt8>) {
        terminalView.terminal.feed(byteArray: Array(slice))
    }
    
    func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
        print("进程已终止")
        // 可以在这里重启进程或关闭窗口
    }
    
    func getWindowSize() -> winsize {
        var size = winsize()
        size.ws_row = UInt16(terminalView.terminal.rows)
        size.ws_col = UInt16(terminalView.terminal.cols)
        return size
    }
    
    // MARK: - 其他TerminalViewDelegate协议方法
    
    func bell(source: TerminalView) {
        NSSound.beep()
    }
    
    func clipboardCopy(source: TerminalView, content: Data) {
        // 不需要实现
    }
    
    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
        // 不需要实现
    }
    
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        // 不需要实现
    }
    
    func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        // 使用默认实现
        if let fixedup = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = NSURLComponents(string: fixedup) {
                if let nested = url.url {
                    NSWorkspace.shared.open(nested)
                }
            }
        }
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
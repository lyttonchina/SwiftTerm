//
//  ViewController.swift
//  MacTerminal
//
//  Created by Miguel de Icaza on 3/11/20.
//  Copyright © 2020 Miguel de Icaza. All rights reserved.
//

import Foundation
import Cocoa
import SwiftTerm
import ObjectiveC
import SwiftUI
import Combine

class ViewController: NSViewController, LocalProcessTerminalViewDelegate, NSUserInterfaceValidations, ObservableObject {
    @IBOutlet var loggingMenuItem: NSMenuItem?

    var changingSize = false
    var logging: Bool = false
    var zoomGesture: NSMagnificationGestureRecognizer?
    var postedTitle: String = ""
    var postedDirectory: String? = nil
    
    // 定义主题
    lazy var darkTheme: [SwiftTerm.Color] = [
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
        SwiftTerm.Color(red: 255, green: 255, blue: 255)
    ]
    
    lazy var lightTheme: [SwiftTerm.Color] = [
        // 白色 (背景) - 确保值为有效的白色
        SwiftTerm.Color(red: 65535, green: 65535, blue: 65535),
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
        // 黑色 (前景) - 确保值为有效的黑色
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
        SwiftTerm.Color(red: 255, green: 255, blue: 255)
    ]

    // 定义主题结构
    class ThemeColor {
        let ansi: [SwiftTerm.Color]      // ANSI颜色集
        let foreground: SwiftTerm.Color  // 前景色
        let background: SwiftTerm.Color  // 背景色
        let cursor: SwiftTerm.Color      // 光标色
        let selectionColor: SwiftTerm.Color // 选中文本背景色
        let isLight: Bool                // 是否是亮色主题
        
        // 从ANSI颜色集构建主题
        init(ansiColors: [SwiftTerm.Color], isLight: Bool = false) {
            self.ansi = ansiColors
            self.foreground = ansiColors[7]  // 前景色通常是第7个
            self.background = ansiColors[0]  // 背景色通常是第0个
            self.cursor = ansiColors[7]      // 光标色默认使用前景色
            self.selectionColor = SwiftTerm.Color(red: 50, green: 100, blue: 200) // 蓝色选择背景
            self.isLight = isLight
        }
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {


        print("sizeChanged: \(newCols) \(newRows)")
        print("changingSize: \(changingSize)")

        if changingSize {
            return
        }
        changingSize = true
        //var border = view.window!.frame - view.frame
        var newFrame = terminal.getOptimalFrameSize ()
        let windowFrame = view.window!.frame
        
        newFrame = CGRect (x: windowFrame.minX, y: windowFrame.minY, width: newFrame.width, height: windowFrame.height - view.frame.height + newFrame.height)

        view.window?.setFrame(newFrame, display: true, animate: true)
        changingSize = false
    }
    
    func updateWindowTitle ()
    {
        var newTitle: String
        if let dir = postedDirectory {
            if let uri = URL(string: dir) {
                if postedTitle == "" {
                    newTitle = uri.path
                } else {
                    newTitle = "\(postedTitle) - \(uri.path)"
                }
            } else {
                newTitle = postedTitle
            }
        } else {
            newTitle = postedTitle
        }
        view.window?.title = newTitle
    }
    
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        postedTitle = title
        updateWindowTitle ()
    }
    
    func hostCurrentDirectoryUpdate (source: TerminalView, directory: String?) {
        self.postedDirectory = directory
        updateWindowTitle()
    }
    
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        view.window?.close()
        if let e = exitCode {
            print ("Process terminated with code: \(e)")
        } else {
            print ("Process vanished")
        }
    }
    var terminal: LocalProcessTerminalView!

    static weak var lastTerminal: LocalProcessTerminalView!
    
    func getBufferAsData () -> Data
    {
        return terminal.getTerminal().getBufferAsData ()
    }
    
    func updateLogging ()
    {
//        let path = logging ? "/Users/miguel/Downloads/Logs" : nil
//        terminal.setHostLogging (directory: path)
        NSUserDefaultsController.shared.defaults.set (logging, forKey: "LogHostOutput")
    }
    
    // Returns the shell associated with the current account
    func getShell () -> String
    {
        let bufsize = sysconf(_SC_GETPW_R_SIZE_MAX)
        guard bufsize != -1 else {
            return "/bin/bash"
        }
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufsize)
        defer {
            buffer.deallocate()
        }
        var pwd = passwd()
        var result: UnsafeMutablePointer<passwd>? = UnsafeMutablePointer<passwd>.allocate(capacity: 1)
        
        if getpwuid_r(getuid(), &pwd, buffer, bufsize, &result) != 0 {
            return "/bin/bash"
        }
        return String (cString: pwd.pw_shell)
    }
    
    class TD: TerminalDelegate {
        func send(source: Terminal, data: ArraySlice<UInt8>) {
        }
        
        
    }

    func test () {
        let a = Terminal (delegate: TD ())
        print (a)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        test ()
        terminal = LocalProcessTerminalView(frame: view.frame)
        zoomGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(zoomGestureHandler))
        terminal.addGestureRecognizer(zoomGesture!)
        ViewController.lastTerminal = terminal
        terminal.processDelegate = self
        terminal.feed(text: "Welcome to SwiftTerm")
        
        // 启用主题切换优化
        TerminalView.enableThemeSwitchImprovement()
        
        // 设置主题菜单
        setupThemeMenu()

        let shell = getShell()
        let shellIdiom = "-" + NSString(string: shell).lastPathComponent
        
        FileManager.default.changeCurrentDirectoryPath (FileManager.default.homeDirectoryForCurrentUser.path)
        terminal.startProcess (executable: shell, execName: shellIdiom)
        view.addSubview(terminal)
        logging = NSUserDefaultsController.shared.defaults.bool(forKey: "LogHostOutput")
        updateLogging ()
        
        #if DEBUG_MOUSE_FOCUS
        var t = NSTextField(frame: NSRect (x: 0, y: 100, width: 200, height: 30))
        t.backgroundColor = NSColor.white
        t.stringValue = "Hello - here to test focus switching"
        
        view.addSubview(t)
        #endif
        
        // 添加 SwiftUI 设置视图的托管
        let settingsView = SettingsHostingView(
            showingSettings: self,
            terminal: self.terminal
        )
        settingsView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        settingsView.isHidden = true
        self.view.addSubview(settingsView)
    }
    
    override func viewWillDisappear() {
        //terminal = nil
    }
    
    @objc
    func zoomGestureHandler (_ sender: NSMagnificationGestureRecognizer) {
        if sender.magnification > 0 {
            biggerFont (sender)
        } else {
            smallerFont(sender)
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        changingSize = true
        terminal.frame = view.frame
        changingSize = false
        terminal.needsLayout = true
    }


    @objc @IBAction
    func set80x25 (_ source: AnyObject)
    {
        terminal.resize(cols: 80, rows: 25)
    }

    var lowerCol = 80
    var lowerRow = 25
    var higherCol = 160
    var higherRow = 60
    
    func queueNextSize ()
    {
        // If they requested a stop
        if resizificating == 0 {
            return
        }
        var next = terminal.getTerminal().getDims ()
        if resizificating > 0 {
            if next.cols < higherCol {
                next.cols += 1
            }
            if next.rows < higherRow {
                next.rows += 1
            }
        } else {
            if next.cols > lowerCol {
                next.cols -= 1
            }
            if next.rows > lowerRow {
                next.rows -= 1
            }
        }
        terminal.resize (cols: next.cols, rows: next.rows)
        var direction = resizificating
        
        if next.rows == higherRow && next.cols == higherCol {
            direction = -1
        }
        if next.rows == lowerRow && next.cols == lowerCol {
            direction = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.resizificating = direction
            self.queueNextSize()
        }
    }
    
    var resizificating = 0
    
    @objc @IBAction
    func resizificator (_ source: AnyObject)
    {
        if resizificating != 1 {
            resizificating = 1
            queueNextSize ()
        } else {
            resizificating = 0
        }
    }

    @objc @IBAction
    func resizificatorDown (_ source: AnyObject)
    {
        if resizificating != -1 {
            resizificating = -1
            queueNextSize ()
        } else {
            resizificating = 0
        }
    }

    @objc @IBAction
    func allowMouseReporting (_ source: AnyObject)
    {
        terminal.allowMouseReporting.toggle ()
    }
    
    @objc @IBAction
    func exportBuffer (_ source: AnyObject)
    {
        saveData { self.terminal.getTerminal().getBufferAsData () }
    }

    @objc @IBAction
    func exportSelection (_ source: AnyObject)
    {
        saveData {
            if let str = self.terminal.getSelection () {
                return str.data (using: .utf8) ?? Data ()
            }
            return Data ()
        }
    }

    func saveData (_ getData: @escaping () -> Data)
    {
        let savePanel = NSSavePanel ()
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        savePanel.title = "Export Buffer Contents As Text"
        savePanel.nameFieldStringValue = "TerminalCapture"
        
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let data = getData ()
                if let url = savePanel.url {
                    do {
                        try data.write(to: url)
                    } catch let error as NSError {
                        let alert = NSAlert (error: error)
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    @objc @IBAction
    func softReset (_ source: AnyObject)
    {
        terminal.getTerminal().softReset ()
        terminal.setNeedsDisplay(terminal.frame)
    }
    
    @objc @IBAction
    func hardReset (_ source: AnyObject)
    {
        terminal.getTerminal().resetToInitialState ()
        terminal.setNeedsDisplay(terminal.frame)
    }
    
    @objc @IBAction
    func toggleOptionAsMetaKey (_ source: AnyObject)
    {
        terminal.optionAsMetaKey.toggle ()
    }
    
    @objc @IBAction
    func biggerFont (_ source: AnyObject)
    {
        let size = terminal.font.pointSize
        guard size < 72 else {
            return
        }
        
        changeFontSizeSmoothly(size + 1)
    }

    @objc @IBAction
    func smallerFont (_ source: AnyObject)
    {
        let size = terminal.font.pointSize
        guard size > 5 else {
            return
        }
        
        changeFontSizeSmoothly(size - 1)
    }

    @objc @IBAction
    func defaultFontSize  (_ source: AnyObject)
    {
        changeFontSizeSmoothly(NSFont.systemFontSize)
    }
    

    @objc @IBAction
    func addTab (_ source: AnyObject)
    {
        
//        if let win = view.window {
//            win.tabbingMode = .preferred
//            if let wc = win.windowController {
//                if let d = wc.document as? Document {
//                    do {
//                        let x = Document()
//                        x.makeWindowControllers()
//                        
//                        try NSDocumentController.shared.newDocument(self)
//                    } catch {}
//                    print ("\(d.debugDescription)")
//                }
//            }
//        }
//            win.tabbingMode = .preferred
//            win.addTabbedWindow(win, ordered: .above)
//
//            if let wc = win.windowController {
//                wc.newWindowForTab(self()
//                wc.showWindow(source)
//            }
//        }
    }
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool
    {
        if item.action == #selector(debugToggleHostLogging(_:)) {
            if let m = item as? NSMenuItem {
                m.state = logging ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        if item.action == #selector(resizificator(_:)) {
            if let m = item as? NSMenuItem {
                m.state = resizificating == 1 ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        if item.action == #selector(resizificatorDown(_:)) {
            if let m = item as? NSMenuItem {
                m.state = resizificating == -1 ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        if item.action == #selector(allowMouseReporting(_:)) {
            if let m = item as? NSMenuItem {
                m.state = terminal.allowMouseReporting ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        if item.action == #selector(toggleOptionAsMetaKey(_:)) {
            if let m = item as? NSMenuItem {
                m.state = terminal.optionAsMetaKey ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        
        // Only enable "Export selection" if we have a selection
        if item.action == #selector(exportSelection(_:)) {
            return terminal.selectionActive
        }
        return true
    }
    
    @objc @IBAction
    func debugToggleHostLogging (_ source: AnyObject)
    {
        logging = !logging
        updateLogging()
    }
    
    // 设置主题菜单
    func setupThemeMenu() {
        let themeMenu = NSMenu(title: "主题")
        
        // 添加主题选项
        let darkThemeItem = NSMenuItem(title: "暗色主题", action: #selector(switchToDarkTheme), keyEquivalent: "d")
        darkThemeItem.keyEquivalentModifierMask = .command
        themeMenu.addItem(darkThemeItem)
        
        let lightThemeItem = NSMenuItem(title: "亮色主题", action: #selector(switchToLightTheme), keyEquivalent: "l")
        lightThemeItem.keyEquivalentModifierMask = .command
        themeMenu.addItem(lightThemeItem)
        
        // 添加传统方式主题切换选项
        themeMenu.addItem(NSMenuItem.separator())
        let traditionalItem = NSMenuItem(title: "传统方式切换(会闪烁)", action: #selector(switchThemeTraditional), keyEquivalent: "t")
        traditionalItem.keyEquivalentModifierMask = .command
        themeMenu.addItem(traditionalItem)
        
        // 添加到主菜单
        let themeMenuItem = NSMenuItem(title: "主题", action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeMenu
        
        if let mainMenu = NSApplication.shared.mainMenu {
            // 在文件菜单之后插入主题菜单
            mainMenu.insertItem(themeMenuItem, at: 1)
        }
        
        // 添加字体大小菜单
        setupFontSizeMenu()
        
        // 添加设置菜单
        setupSettingsMenu()
    }
    
    // 设置字体大小菜单
    func setupFontSizeMenu() {
        let fontSizeMenu = NSMenu(title: "字体大小")
        
        // 增大字体选项
        let increaseFontItem = NSMenuItem(title: "增大字体", action: #selector(biggerFont(_:)), keyEquivalent: "+")
        increaseFontItem.keyEquivalentModifierMask = .command
        fontSizeMenu.addItem(increaseFontItem)
        
        // 减小字体选项
        let decreaseFontItem = NSMenuItem(title: "减小字体", action: #selector(smallerFont(_:)), keyEquivalent: "-")
        decreaseFontItem.keyEquivalentModifierMask = .command
        fontSizeMenu.addItem(decreaseFontItem)
        
        // 恢复默认字体大小
        let defaultFontItem = NSMenuItem(title: "默认字体大小", action: #selector(defaultFontSize(_:)), keyEquivalent: "0")
        defaultFontItem.keyEquivalentModifierMask = .command
        fontSizeMenu.addItem(defaultFontItem)
        
        // 分隔线
        fontSizeMenu.addItem(NSMenuItem.separator())
        
        // 预设字体大小选项
        let fontSizes = [10, 12, 14, 16, 18, 20, 24, 28, 32]
        for size in fontSizes {
            let fontSizeItem = NSMenuItem(title: "\(size) 号字体", action: #selector(setCustomFontSize(_:)), keyEquivalent: "")
            fontSizeItem.tag = size
            fontSizeMenu.addItem(fontSizeItem)
        }
        
        // 添加到主菜单
        let fontSizeMenuItem = NSMenuItem(title: "字体大小", action: nil, keyEquivalent: "")
        fontSizeMenuItem.submenu = fontSizeMenu
        
        if let mainMenu = NSApplication.shared.mainMenu {
            // 在主题菜单之后插入字体大小菜单
            mainMenu.insertItem(fontSizeMenuItem, at: 2)
        }
    }
    
    // 添加设置菜单
    func setupSettingsMenu() {
        if let mainMenu = NSApplication.shared.mainMenu {
            // 创建设置菜单
            let settingsMenu = NSMenu(title: "设置")
            
            // 创建设置菜单项
            let settingsMenuItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
            settingsMenuItem.keyEquivalentModifierMask = .command
            
            // 将设置菜单项添加到设置菜单
            settingsMenu.addItem(settingsMenuItem)
            
            // 创建设置主菜单项
            let settingsMainMenuItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
            settingsMainMenuItem.submenu = settingsMenu
            
            // 在主题菜单之后插入设置菜单
            mainMenu.insertItem(settingsMainMenuItem, at: 2)
        }
    }
    
    // 添加 showingSettings 状态变量
    @Published var showingSettings = false
    
    // 更新 openSettings 方法
    @objc func openSettings() {
        self.showingSettings = true
    }
    
    // 平滑更改字体大小而不清屏
    func changeFontSizeSmoothly(_ size: CGFloat) {
        print("开始更改字体大小到: \(size)pt")
        
        // 创建新字体
        let newFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        
        // 停用动画以减少闪烁
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        
        // 关键：设置changingSize标志为true，阻止sizeChanged方法调整窗口大小
        changingSize = true
        
        // 更新字体而不清屏
        terminal.setFont(newFont, clearScreen: false)
        
        // 调整terminal frame以确保正确的行列计算
        // 这会触发processSizeChange方法，但因为changingSize=true，sizeChanged不会调整窗口
        terminal.frame = view.frame
        
        // 强制重绘
        terminal.needsDisplay = true
        
        // 重置标志
        changingSize = false
        
        // 结束动画组
        NSAnimationContext.endGrouping()
        
        print("字体大小更改完成：\(size)pt")
    }

    // 设置自定义字体大小
    @objc func setCustomFontSize(_ sender: NSMenuItem) {
        let fontSize = CGFloat(sender.tag)
        changeFontSizeSmoothly(fontSize)
    }
    
    // 定义深色主题
    var darkThemeColor: ThemeColor {
        return ThemeColor(ansiColors: darkTheme, isLight: false)
    }
    
    // 定义浅色主题
    var lightThemeColor: ThemeColor {
        return ThemeColor(ansiColors: lightTheme, isLight: true)
    }
    
    // 切换到暗色主题
    @objc func switchToDarkTheme() {
        print("平滑切换到暗色主题")
        safeApplyTheme(theme: darkThemeColor)
    }
    
    // 切换到亮色主题
    @objc func switchToLightTheme() {
        print("平滑切换到亮色主题")
        safeApplyTheme(theme: lightThemeColor)
    }
    
    // 传统方式切换主题（会有闪烁）
    @objc func switchThemeTraditional() {
        print("使用传统方式切换主题（会看到闪烁）")
        if terminal.nativeBackgroundColor.brightnessComponent > 0.5 {
            terminal.installColors(darkTheme)
        } else {
            terminal.installColors(lightTheme)
        }
    }
    
    // 安全应用主题的方法
    private func safeApplyTheme(theme: ThemeColor) {
        // 打印主题信息
        print("===== 主题信息 =====")
        print("背景色: R:\(theme.background.red), G:\(theme.background.green), B:\(theme.background.blue)")
        print("前景色: R:\(theme.foreground.red), G:\(theme.foreground.green), B:\(theme.foreground.blue)")
        print("光标色: R:\(theme.cursor.red), G:\(theme.cursor.green), B:\(theme.cursor.blue)")
        print("ANSI颜色集: \(theme.ansi.count)个颜色")
        print("===================")
        
        print("开始应用主题...")
        
        // 正确转换背景色
        let bgColor = theme.background
        print("原始背景色值: R:\(bgColor.red/256), G:\(bgColor.green/256), B:\(bgColor.blue/256)")

        // 确保值在0-1范围内
        // SwiftTerm.Color值范围是0-65535，需要除以65535转换为0-1范围
        let nsBackgroundColor: NSColor
        // 简化条件判断
        let isWhiteBg = theme.background.red > 60000 && theme.background.green > 60000 && theme.background.blue > 60000
        let isBlackBg = theme.background.red < 5000 && theme.background.green < 5000 && theme.background.blue < 5000

        print("isWhiteBg: \(isWhiteBg), isBlackBg: \(isBlackBg), 背景色R: \(theme.background.red), G: \(theme.background.green), B: \(theme.background.blue)")

        // 对亮色主题进行特殊处理
        if theme.isLight {
            // 强制使用白色背景
            nsBackgroundColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            print("强制使用白色背景")
        } else {
            // 强制使用黑色背景
            nsBackgroundColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            print("强制使用黑色背景")
        }

        // 同样处理前景色
        // 获取前景色
        let nsForegroundColor: NSColor
        // 简化条件判断
        let isBlackFg = theme.foreground.red < 5000 && theme.foreground.green < 5000 && theme.foreground.blue < 5000
        let isWhiteFg = theme.foreground.red > 60000 && theme.foreground.green > 60000 && theme.foreground.blue > 60000

        print("isWhiteFg: \(isWhiteFg), isBlackFg: \(isBlackFg), 前景色R: \(theme.foreground.red), G: \(theme.foreground.green), B: \(theme.foreground.blue)")

        // 对亮色主题进行特殊处理
        if theme.isLight {
            // 强制使用黑色前景
            nsForegroundColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            print("强制使用黑色前景")
        } else {
            // 强制使用白色前景
            nsForegroundColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            print("强制使用白色前景")
        }

        print("使用背景色: \(nsBackgroundColor)")
        print("使用前景色: \(nsForegroundColor)")

        // 应用顺序调整:
        // 1. 先设置ANSI颜色集
        print("设置ANSI颜色集...")
        terminal.installColors(theme.ansi)

        // 2. 设置终端内部颜色
        let terminalController = terminal.getTerminal()
        print("设置终端内部颜色...")
        terminalController.backgroundColor = theme.background
        terminalController.foregroundColor = theme.foreground

        // 3. 最后设置原生颜色
        print("设置原生背景色和前景色...")
        terminal.nativeBackgroundColor = nsBackgroundColor
        terminal.nativeForegroundColor = nsForegroundColor

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
        terminal.caretColor = cursorColor

        // 强制重绘
        print("强制重绘视图...")
        terminal.setNeedsDisplay(terminal.bounds)

        // 打印最终应用的颜色
        print("---- 应用后的颜色状态 ----")
        // 转换为sRGB颜色空间再获取组件
        let finalBg = terminal.nativeBackgroundColor.usingColorSpace(NSColorSpace.sRGB) ?? terminal.nativeBackgroundColor
        let finalFg = terminal.nativeForegroundColor.usingColorSpace(NSColorSpace.sRGB) ?? terminal.nativeForegroundColor

        // 简化打印
        print("背景色信息: \(finalBg.description)")
        print("前景色信息: \(finalFg.description)")
        print("--------------------------")

        print("主题已应用完成")
    }
}

// 颜色扩展，用于计算亮度
extension SwiftTerm.Color {
    var brightness: CGFloat {
        let r = CGFloat(red) / 65535.0
        let g = CGFloat(green) / 65535.0
        let b = CGFloat(blue) / 65535.0
        return (r * 0.299 + g * 0.587 + b * 0.114)
    }
}

// 为 NSColor 添加亮度计算扩展
extension NSColor {
    var brightnessComponent: CGFloat {
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            return 0.5 // 默认中等亮度
        }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        // 计算亮度 (基于标准亮度公式)
        return (red * 0.299 + green * 0.587 + blue * 0.114)
    }
}

// 添加 SettingsHostingView 类
class SettingsHostingView: NSView {
    private var hostingView: NSHostingView<SettingsWrapperView>?
    private weak var viewController: ViewController?
    private var terminal: LocalProcessTerminalView
    
    init(showingSettings: ViewController, terminal: LocalProcessTerminalView) {
        self.viewController = showingSettings
        self.terminal = terminal
        super.init(frame: .zero)
        
        let wrapperView = SettingsWrapperView(
            showingSettings: showingSettings,
            terminal: terminal
        )
        
        self.hostingView = NSHostingView(rootView: wrapperView)
        if let hostingView = self.hostingView {
            self.addSubview(hostingView)
            hostingView.frame = self.bounds
            hostingView.autoresizingMask = [.width, .height]
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 添加 SettingsWrapperView 结构体
struct SettingsWrapperView: View {
    @ObservedObject var showingSettings: ViewController
    var terminal: LocalProcessTerminalView
    
    var body: some View {
        EmptyView()
            .sheet(isPresented: Binding<Bool>(
                get: { self.showingSettings.showingSettings },
                set: { self.showingSettings.showingSettings = $0 }
            )) {
                // 使用内部定义的 RunningTerminalConfig
                TerminalSettingsView(
                    terminal: self.terminal
                )
            }
    }
}

// 在 ViewController.swift 中定义设置视图
struct TerminalSettingsView: View {
    var terminal: LocalProcessTerminalView
    @Environment(\.presentationMode) var presentationMode
    
    @State var style: String = "Dark"
    @State var background: String = "Solid"
    @State var fontName: String = "Menlo"
    @State var fontSize: CGFloat = 13.0
    
    func save() {
        // 根据主题切换颜色
        if let viewController = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            if style == "Dark" {
                viewController.switchToDarkTheme()
            } else {
                viewController.switchToLightTheme()
            }
            
            // 更新字体
            viewController.changeFontSizeSmoothly(fontSize)
        }
        
        // 关闭设置窗口
        self.presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        VStack {
            Form {
                // 主题选择
                Group {
                    Text("主题选择")
                        .font(.headline)
                    
                    HStack {
                        Button(action: {
                            style = "Dark"
                        }) {
                            VStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black)
                                    .frame(width: 100, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(style == "Dark" ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                Text("暗色主题")
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            style = "Light"
                        }) {
                            VStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 100, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(style == "Light" ? Color.blue : Color.gray, lineWidth: 3)
                                    )
                                Text("亮色主题")
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 背景样式
                Group {
                    Text("背景样式")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Picker("背景样式", selection: $background) {
                        Text("纯色").tag("Solid")
                        Text("渐变").tag("Gradient")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 字体选择
                Group {
                    Text("字体选择")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Picker("字体", selection: $fontName) {
                        Text("Menlo").tag("Menlo")
                        Text("Monaco").tag("Monaco")
                        Text("Courier").tag("Courier")
                        Text("SF Mono").tag("SF Mono")
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                }
                
                // 字体大小
                Group {
                    Text("字体大小: \(Int(fontSize))")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    HStack {
                        Text("10")
                        Slider(value: $fontSize, in: 10...24, step: 1)
                        Text("24")
                    }
                }
            }
            .padding(20)

            HStack {
                Button("取消") {
                    self.presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("保存") {
                    save()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 400)
        .onAppear() {
            // 初始化当前值
            style = terminal.nativeBackgroundColor.brightnessComponent < 0.5 ? "Dark" : "Light"
            fontSize = terminal.font.pointSize
        }
    }
}

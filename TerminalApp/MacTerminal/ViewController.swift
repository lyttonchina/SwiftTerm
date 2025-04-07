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
import IOKit

// 为SwiftTerm.TerminalView.TerminalThemeColor提供一个类型别名（如果需要的话）
// typealias TerminalThemeColor = SwiftTerm.TerminalView.TerminalThemeColor

class ViewController: NSViewController, LocalProcessTerminalViewDelegate, NSWindowDelegate, ObservableObject {
    @IBOutlet var loggingMenuItem: NSMenuItem?

    // 追踪菜单是否已被设置
    static var menuInitialized = false

    var changingSize = false
    var logging: Bool = false
    var postedTitle: String = ""
    var postedDirectory: String? = nil
    
    // 终端进程
    var terminal: LocalProcessTerminalView!
    // 终端容器视图
    var containerView: TerminalContainerView!
    // 是否使用透明背景
    var transparent: Bool = false

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
        
        // 创建终端视图
        terminal = LocalProcessTerminalView(frame: view.frame)
        ViewController.lastTerminal = terminal
        terminal.processDelegate = self
        
        // 启用主题切换优化
        TerminalView.enableThemeSwitchImprovement()
        
        // 设置设置菜单
        setupSettingsMenu()
        
        // 创建容器视图包装终端，提供边距
        containerView = terminal.withContainer(insets: NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        
        // 设置容器视图的背景色
        if !transparent {
            print("初始化: 即将同步容器背景色")
            containerView.syncBackgroundColor()
            print("初始化: 容器背景色同步完成")
        } else {
            print("初始化: 设置透明背景")
            containerView.backgroundColor = NSColor.clear
        }
        
        // 添加容器视图而不是直接添加终端视图
        view.addSubview(containerView)
        
        // 确保容器视图填充整个视图区域
        containerView.frame = view.bounds
        containerView.autoresizingMask = [.width, .height]
        
        // 强制刷新
        containerView.needsDisplay = true
        
        // 恢复启动shell的代码
        let shell = getShell()
        let shellIdiom = "-" + NSString(string: shell).lastPathComponent
        
        FileManager.default.changeCurrentDirectoryPath (FileManager.default.homeDirectoryForCurrentUser.path)
        terminal.startProcess (executable: shell, execName: shellIdiom)
        
        logging = NSUserDefaultsController.shared.defaults.bool(forKey: "LogHostOutput")
        updateLogging ()
        
        // 订阅主题变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemeChange(_:)),
            name: Notification.Name("ThemeChanged"),
            object: nil
        )
        
        // 应用当前主题
        applyTheme(themeName: settings.themeName)
        
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
        
        // 同步容器背景色
        syncContainerBackgroundColor()
    }
    
    // 同步容器背景色
    func syncContainerBackgroundColor() {
        if !transparent {
            print("VC.syncContainerBackgroundColor: 终端当前背景色为 \(terminal.nativeBackgroundColor)")
            containerView.syncBackgroundColor()
            
            // 确保同步后强制刷新
            containerView.layer?.backgroundColor = containerView.backgroundColor.cgColor
            containerView.needsDisplay = true
            
            print("VC.syncContainerBackgroundColor: 同步后容器背景色为 \(containerView.backgroundColor)")
        } else {
            containerView.backgroundColor = NSColor.clear
            containerView.layer?.backgroundColor = NSColor.clear.cgColor
            containerView.needsDisplay = true
            print("VC.syncContainerBackgroundColor: 设置容器为透明背景")
        }
    }
    
    @objc func handleThemeChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let themeName = userInfo["themeName"] as? String {
            print("收到主题变更通知: \(themeName)")
            
            // 应用主题
            applyTheme(themeName: themeName)
            
            // 主题变更后在稍后同步容器背景色 (已在applyTheme内部处理)
        }
    }
    
    deinit {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear() {
        //terminal = nil
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        changingSize = true
        // 调整容器视图而不是直接调整终端视图
        containerView.frame = view.frame
        changingSize = false
        containerView.needsLayout = true
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
        if item.action == #selector(toggleTransparentBackground(_:)) {
            if let m = item as? NSMenuItem {
                m.state = transparent ? NSControl.StateValue.on : NSControl.StateValue.off
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
    
    // 设置菜单
    func setupSettingsMenu() {
        // 如果菜单已初始化，则不需要再次设置
        if ViewController.menuInitialized {
            return
        }
        
        if let mainMenu = NSApplication.shared.mainMenu {
            // 检查主菜单中是否已经存在设置菜单
            for item in mainMenu.items {
                if item.title == "设置" {
                    // 设置菜单已存在，直接返回
                    ViewController.menuInitialized = true
                    return
                }
            }
            
            // 创建设置菜单
            let settingsMenu = NSMenu(title: "设置")
            
            // 创建设置菜单项
            let settingsMenuItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
            settingsMenuItem.keyEquivalentModifierMask = .command
            
            // 将设置菜单项添加到设置菜单
            settingsMenu.addItem(settingsMenuItem)
            
            // 添加分隔线
            settingsMenu.addItem(NSMenuItem.separator())
            
            // 添加透明背景选项
            let transparentMenuItem = NSMenuItem(title: "透明背景", action: #selector(toggleTransparentBackground(_:)), keyEquivalent: "t")
            transparentMenuItem.keyEquivalentModifierMask = [.command, .option]
            transparentMenuItem.state = transparent ? .on : .off
            settingsMenu.addItem(transparentMenuItem)
            
            // 创建设置主菜单项
            let settingsMainMenuItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
            settingsMainMenuItem.submenu = settingsMenu
            
            // 在文件菜单之后插入设置菜单
            mainMenu.insertItem(settingsMainMenuItem, at: 1)
            
            // 标记菜单已被初始化
            ViewController.menuInitialized = true
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
        
        // 使用SwiftTerm提供的方法
        terminal.changeFontSizeSmoothly(size)
        
        print("字体大小更改完成：\(size)pt")
    }
    
    // 平滑更改字体
    func changeFontSmoothly(_ fontName: String, size: CGFloat = 0) {
        print("开始更改字体到: \(fontName), 大小: \(size)pt")
        
        // 使用SwiftTerm提供的方法
        terminal.changeFontSmoothly(fontName: fontName, size: size)
        
        print("字体更改完成：\(fontName), \(size)pt")
    }

    // 应用自定义主题
    func applyTheme(themeName: String) {
        if let theme = themes.first(where: { $0.name == themeName }) {
            print("应用主题: \(themeName)")
            
            // 创建用于TerminalView的ThemeColor
            let terminalTheme = TerminalView.TerminalThemeColor(
                ansiColors: theme.ansi,
                foreground: theme.foreground, 
                background: theme.background,
                cursor: theme.cursor,
                selectionColor: theme.selectionColor,
                isLight: isLightColor(theme.background)
            )
            
            // 调用 SwiftTerm 的 applyTheme 方法
            terminal.applyTheme(theme: terminalTheme)
            
            // 稍微延迟同步容器背景色，确保终端视图背景色已更新
            DispatchQueue.main.async {
                print("主题应用后: 即将同步容器背景色")
                self.syncContainerBackgroundColor()
                
                // 强制刷新容器视图
                self.containerView.needsDisplay = true
                print("主题应用后: 容器背景色同步完成")
            }
            
            print("主题已应用: \(themeName)")
        } else {
            print("未找到名为 \(themeName) 的主题")
        }
    }
    
    // 判断一个颜色是否为亮色
    private func isLightColor(_ color: SwiftTerm.Color) -> Bool {
        let r = Double(color.red) / 65535.0
        let g = Double(color.green) / 65535.0
        let b = Double(color.blue) / 65535.0
        let brightness = r * 0.299 + g * 0.587 + b * 0.114
        return brightness > 0.5
    }
    
    // 处理终端大小变化
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        print("sizeChanged: \(newCols) \(newRows)")
        
        // 如果终端正在更改字体大小，不调整窗口大小
        if terminal.isFontSizeChanging() {
            return
        }
        
        changingSize = true
        var newFrame = terminal.getOptimalFrameSize()
        let windowFrame = view.window!.frame
        
        // 考虑容器视图的边距
        let insets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) // 使用创建容器时的边距
        let extraWidth = insets.left + insets.right
        let extraHeight = insets.top + insets.bottom
        
        // 调整窗口大小，考虑容器边距
        newFrame = CGRect(
            x: windowFrame.minX, 
            y: windowFrame.minY, 
            width: newFrame.width + extraWidth, 
            height: windowFrame.height - view.frame.height + newFrame.height + extraHeight
        )

        view.window?.setFrame(newFrame, display: true, animate: true)
        changingSize = false
    }
    
    // 更新窗口标题
    func updateWindowTitle() {
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
    
    // 设置终端标题
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        postedTitle = title
        updateWindowTitle()
    }
    
    // 主机当前目录更新
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        self.postedDirectory = directory
        updateWindowTitle()
    }
    
    // 进程终止处理
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        view.window?.close()
        if let e = exitCode {
            print("Process terminated with code: \(e)")
        } else {
            print("Process vanished")
        }
    }

    // 添加透明背景切换功能
    @objc @IBAction
    func toggleTransparentBackground(_ sender: AnyObject) {
        transparent.toggle()
        syncContainerBackgroundColor()
        
        // 更新菜单项状态
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = transparent ? .on : .off
        }
    }

    // 这个函数创建一个临时的shell配置文件，用于隐藏提示符
    func createNoPromptShellConfig() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let configPath = tempDir.appendingPathComponent("no_prompt_config.sh")
        
        let configContent = """
        # 隐藏提示符的配置
        export PS1=""
        """
        
        do {
            try configContent.write(to: configPath, atomically: true, encoding: .utf8)
            return configPath.path
        } catch {
            print("无法创建shell配置文件: \(error)")
            return ""
        }
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
                // 使用ConfigurableTerminalMacOs.swift中的RunningTerminalConfig
                RunningTerminalConfig(
                    showingModal: Binding<Bool>(
                        get: { self.showingSettings.showingSettings },
                        set: { self.showingSettings.showingSettings = $0 }
                    ),
                    terminal: self.terminal
                )
            }
    }
}

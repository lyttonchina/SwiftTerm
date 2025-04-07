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

class ViewController: NSViewController, LocalProcessTerminalViewDelegate, NSWindowDelegate, TerminalViewDelegate, ObservableObject {
    @IBOutlet var loggingMenuItem: NSMenuItem?

    // 追踪菜单是否已被设置
    static var menuInitialized = false

    var changingSize = false
    var logging: Bool = false
    var postedTitle: String = ""
    var postedDirectory: String? = nil
    
    // 终端进程
    var terminal: LocalProcessTerminalView!
    // 终端配置器
    var configurator: TerminalConfigurator!
    // 终端代理链
    var delegateChain: TerminalDelegateChain!
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
        
        // 确保TerminalThemeManager知道所有设置中定义的主题
        initializeThemeManager()
        
        // 打印所有可用主题，确认主题已注册
        let allThemes = TerminalThemeManager.shared.getAllThemes()
        print("应用启动时可用主题: \(allThemes.map { $0.name }.joined(separator: ", "))")
        
        // 创建终端视图
        terminal = LocalProcessTerminalView(frame: view.frame)
        ViewController.lastTerminal = terminal
        
        // 设置多代理支持
        delegateChain = terminal.useMultipleDelegates()
        delegateChain.add(delegate: self)
        
        // 设置配置器
        configurator = terminal.configure()
        
        // 设置进程代理
        terminal.processDelegate = self
        
        // 设置设置菜单
        setupSettingsMenu()
        
        // 确保能访问容器视图
        let containerView = configurator.containerView
        
        // 设置容器视图的背景色
        if !transparent {
            print("初始化: 即将同步容器背景色")
            containerView.syncBackgroundColor()
            print("初始化: 容器背景色同步完成")
        } else {
            print("初始化: 设置透明背景")
            configurator.enableTransparentBackground(true)
        }
        
        // 添加容器视图而不是直接添加终端视图
        view.addSubview(containerView)
        
        // 确保容器视图填充整个视图区域
        containerView.frame = view.bounds
        containerView.autoresizingMask = [.width, .height]
        
        // 强制刷新
        containerView.needsDisplay = true
        
        // 启动shell
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
    }
    
    @objc func handleThemeChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let themeName = userInfo["themeName"] as? String {
            print("收到主题变更通知: \(themeName)")
            
            // 打印更多调试信息
            print("当前ViewController: \(self)")
            print("当前terminal: \(String(describing: terminal))")
            print("当前configurator: \(String(describing: configurator))")
            
            // 应用主题
            if let theme = TerminalThemeManager.shared.getTheme(named: themeName) {
                print("找到主题: \(themeName), 准备应用")
                applyTheme(themeName: themeName)
            } else {
                print("错误: 未找到名为 \(themeName) 的主题")
            }
        } else {
            print("错误: 收到的主题变更通知不包含themeName")
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
        configurator.containerView.frame = view.frame
        changingSize = false
        configurator.containerView.needsLayout = true
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
    
    // 初始化主题管理器，使其包含设置文件中定义的所有主题
    private func initializeThemeManager() {
        print("正在初始化TerminalThemeManager，添加SettingsViewMacOs.swift中定义的主题")
        
        // 将SettingsViewMacOs.swift中定义的主题添加到TerminalThemeManager
        for localTheme in themes {
            print("准备注册主题到TerminalThemeManager: \(localTheme.name)")
            
            // 创建SwiftTerm.ThemeColor实例
            // 注意：由于命名空间冲突，我们需要明确指定SwiftTerm.ThemeColor
            let swiftTermTheme = SwiftTerm.ThemeColor(
                name: localTheme.name,
                ansi: localTheme.ansi,
                background: localTheme.background,
                foreground: localTheme.foreground,
                cursor: localTheme.cursor,
                cursorText: localTheme.cursorText,
                selectedText: localTheme.selectedText,
                selectionColor: localTheme.selectionColor
            )
            
            // 注册到TerminalThemeManager
            TerminalThemeManager.shared.registerTheme(swiftTermTheme)
        }
        
        // 打印所有已注册的主题，确认注册成功
        print("TerminalThemeManager现在包含的主题: \(TerminalThemeManager.shared.getAllThemes().map { $0.name }.joined(separator: ", "))")
    }
    
    // 添加 showingSettings 状态变量
    @Published var showingSettings = false
    
    // 更新 openSettings 方法
    @objc func openSettings() {
        self.showingSettings = true
    }
    
    // 平滑更改字体大小
    func changeFontSize(_ size: CGFloat) {
        configurator.applyFont(name: "", size: size)
    }
    
    // 平滑更改字体
    func changeFont(_ fontName: String, size: CGFloat = 0) {
        configurator.applyFont(name: fontName, size: size)
    }

    // 应用自定义主题
    func applyTheme(themeName: String) {
        print("开始应用主题: \(themeName)")
        if let theme = TerminalThemeManager.shared.getTheme(named: themeName) {
            print("应用主题: \(themeName), Theme对象: \(theme)")
            
            // 检查configurator是否有效
            if configurator != nil {
                print("configurator有效，调用configurator.applyTheme")
                configurator.applyTheme(theme)
            } else {
                print("错误: configurator为nil")
            }
        } else {
            print("未找到名为 \(themeName) 的主题")
            
            // 打印所有可用主题
            let allThemes = TerminalThemeManager.shared.getAllThemes()
            print("可用主题: \(allThemes.map { $0.name }.joined(separator: ", "))")
        }
    }
    
    // 处理终端大小变化
    public func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        print("TerminalViewDelegate.sizeChanged: \(newCols) \(newRows)")
        if let localSource = source as? LocalProcessTerminalView {
            // Forward to our LocalProcessTerminalViewDelegate implementation
            sizeChanged(source: localSource, newCols: newCols, newRows: newRows)
        }
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
    public func setTerminalTitle(source: TerminalView, title: String) {
        print("TerminalViewDelegate.setTerminalTitle: \(title)")
        if let localSource = source as? LocalProcessTerminalView {
            // Forward to our LocalProcessTerminalViewDelegate implementation
            setTerminalTitle(source: localSource, title: title)
        } else {
            // Handle non-LocalProcessTerminalView sources
            postedTitle = title
            updateWindowTitle()
        }
    }    
    


    // 透明背景切换功能
    @objc @IBAction
    func toggleTransparentBackground(_ sender: AnyObject) {
        transparent.toggle()
        configurator.enableTransparentBackground(transparent)
        
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

    // MARK: - TerminalViewDelegate Methods
    
    public func scrolled(source: TerminalView, position: Double) {
        // Handle scrolling if needed
    }
    
    public func send(source: TerminalView, data: ArraySlice<UInt8>) {
        // In our case, LocalProcessTerminalView handles this already
    }
    
    public func clipboardCopy(source: TerminalView, content: Data) {
        if let str = String(bytes: content, encoding: .utf8) {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.writeObjects([str as NSString])
        }
    }
    
    public func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        // Handle range changes if needed
    }
    
    public func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        if let fixedup = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = NSURLComponents(string: fixedup) {
                if let nested = url.url {
                    NSWorkspace.shared.open(nested)
                }
            }
        }
    }
    
    public func bell(source: TerminalView) {
        NSSound.beep()
    }
    
    public func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
        // Handle iTerm content if needed
    }

    // MARK: - LocalProcessTerminalViewDelegate Methods
    
    // LocalProcessTerminalViewDelegate method implementations with exact signatures
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        print("LocalProcessTerminalViewDelegate.sizeChanged: \(newCols) \(newRows)")
        
        // Only adjust window size if not changing font and window exists
        if !terminal.isFontSizeChanging() && !changingSize && view.window != nil {
            changingSize = true
            var newFrame = terminal.getOptimalFrameSize()
            let windowFrame = view.window!.frame
            
            // Consider container view margins
            let insets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) 
            let extraWidth = insets.left + insets.right
            let extraHeight = insets.top + insets.bottom
            
            // Adjust window size, considering container margins
            newFrame = CGRect(
                x: windowFrame.minX, 
                y: windowFrame.minY, 
                width: newFrame.width + extraWidth, 
                height: windowFrame.height - view.frame.height + newFrame.height + extraHeight
            )

            view.window?.setFrame(newFrame, display: true, animate: true)
            changingSize = false
        }
    }
    
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        postedTitle = title
        updateWindowTitle()
    }
    
    // Common method to both protocols with same signature - only define once
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        self.postedDirectory = directory
        updateWindowTitle()
    }
    
    // Common method to both protocols with same signature - only define once
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        view.window?.close()
        if let e = exitCode {
            print("Process terminated with code: \(e)")
        } else {
            print("Process vanished")
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

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

class ViewController: NSViewController, LocalProcessTerminalViewDelegate, NSUserInterfaceValidations {
    @IBOutlet var loggingMenuItem: NSMenuItem?

    var changingSize = false
    var logging: Bool = false
    var zoomGesture: NSMagnificationGestureRecognizer?
    var postedTitle: String = ""
    var postedDirectory: String? = nil
    
    // 定义主题 - 使用库提供的实现
    lazy var darkTheme = TerminalView.createDarkTheme()
    lazy var lightTheme = TerminalView.createLightTheme()
    
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
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
    
    // 平滑更改字体大小而不清屏
    private func changeFontSizeSmoothly(_ size: CGFloat) {
        print("开始更改字体大小到: \(size)pt")
        
        // 创建新字体
        let newFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        
        // 安全转换确保存在TerminalView
        if let terminalView = terminal as? SwiftTerm.TerminalView {
            // 使用不清屏的字体设置方法
            terminalView.setFont(newFont, clearScreen: false)
        } else {
            // 回退方案
            terminal.font = newFont
        }
        
        // 确保视图范围大小正确
        if !changingSize {
            changingSize = true
            // 使用getOptimalFrameSize来基于新字体获取正确大小
            var newFrameSize = terminal.getOptimalFrameSize()
            let windowFrame = view.window!.frame
            
            // 保持窗口宽度不变，只调整高度
            newFrameSize = CGRect(
                x: windowFrame.minX,
                y: windowFrame.minY,
                width: windowFrame.width,
                height: windowFrame.height - view.frame.height + newFrameSize.height
            )
            
            view.window?.setFrame(newFrameSize, display: true, animate: false)
            changingSize = false
        }
    }

    // 设置自定义字体大小
    @objc func setCustomFontSize(_ sender: NSMenuItem) {
        let fontSize = CGFloat(sender.tag)
        changeFontSizeSmoothly(fontSize)
    }
    
    // 切换到暗色主题
    @objc func switchToDarkTheme() {
        print("平滑切换到暗色主题")
        // 安全转换确保存在TerminalView
        if let terminalView = terminal as? SwiftTerm.TerminalView {
            // 使用主题切换API
            terminalView.applyTheme(theme: darkTheme)
        }
    }
    
    // 切换到亮色主题
    @objc func switchToLightTheme() {
        print("平滑切换到亮色主题")
        // 安全转换确保存在TerminalView
        if let terminalView = terminal as? SwiftTerm.TerminalView {
            // 使用主题切换API
            terminalView.applyTheme(theme: lightTheme)
        }
    }
    
    // 传统方式切换主题（会有闪烁）
    @objc func switchThemeTraditional() {
        print("使用传统方式切换主题（会看到闪烁）")
        #if os(macOS)
        let isDarkBackground = terminal.nativeBackgroundColor.brightnessComponent > 0.5
        #else
        let isDarkBackground = terminal.backgroundColor.brightness > 0.5
        #endif
        
        // 使用标准installColors方法（会导致闪烁）
        if isDarkBackground {
            terminal.installColors(darkTheme.ansi)
        } else {
            terminal.installColors(lightTheme.ansi)
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



//
//  MacLocalTerminalView.swift
//
//
//  Created by Miguel de Icaza on 3/6/20.
//

#if os(macOS)
import Foundation
import AppKit

/// Delegate for the ``LocalProcessTerminalView`` class that is used to
/// notify the user of process-related changes.
public protocol LocalProcessTerminalViewDelegate: AnyObject {
    /**
     * This method is invoked to notify that the terminal has been resized to the specified number of columns and rows
     * the user interface code might try to adjut the containing scroll view, or if it is a toplevel window, the window itself
     * - Parameter source: the sending instance
     * - Parameter newCols: the new number of columns that should be shown
     * - Parameter newRow: the new number of rows that should be shown
     */
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int)

    /**
     * This method is invoked when the title of the terminal window should be updated to the provided title
     * - Parameter source: the sending instance
     * - Parameter title: the desired title
     */
    func setTerminalTitle(source: LocalProcessTerminalView, title: String)

    /**
     * Invoked when the OSC command 7 for "current directory has changed" command is sent
     * - Parameter source: the sending instance
     * - Parameter directory: the new working directory
     */
    func hostCurrentDirectoryUpdate (source: TerminalView, directory: String?)

    /**
     * This method will be invoked when the child process started by `startProcess` has terminated.
     * - Parameter source: the local process that terminated
     * - Parameter exitCode: the exit code returned by the process, or nil if this was an error caused during the IO reading/writing
     */
    func processTerminated (source: TerminalView, exitCode: Int32?)
}

/**
 * `LocalProcessTerminalView` is an AppKit NSView that can be used to host a local process
 * the process is launched inside a pseudo-terminal.
 *
 * Call the `startProcess` to launch the underlying process inside a pseudo terminal.
 *
 * Generally, for the `LocalProcessTerminalView` to be useful, you will want to disable the sandbox
 * for your application, otherwise the underlying shell will not have access to much - not the majority of
 * commands, not assorted places on the file systems and so on.   For this, you need to disable for your
 * target in "Signing and Capabilities" the sandbox entirely.
 *
 * Note: instances of `LocalProcessTerminalView` will set the `TerminalView`'s `delegate`
 * property and capture and consume the messages.   The messages that are most likely needed for
 * consumer applications are reposted to the `LocalProcessTerminalViewDelegate` in
 * `processDelegate`.   If you override the `delegate` directly, you might inadvertently break
 * the internal working of `LocalProcessTerminalView`.   If you must change the `delegate`
 * make sure that you proxy the values in your implementation to the values set after initializing this instance.
 *
 * If you want additional control over the delegate methods implemented in this class, you can
 * subclass this and override the methods
 */
open class LocalProcessTerminalView: TerminalView, TerminalViewDelegate, LocalProcessDelegate {
    
    var process: LocalProcess!
    // 内部配置器，不对外公开
    private var _configurator: TerminalConfigurator?
    // 标记是否正在更改字体大小
    public var changingFontSize: Bool = false
    
    public override init (frame: CGRect)
    {
        super.init (frame: frame)
        setup ()
    }
    
    /**
     * 初始化并配置终端视图，一步完成初始化和添加到父视图
     * - Parameter frame: 终端视图的框架
     * - Parameter parentView: 父视图，如果提供，将自动添加到该视图
     */
    public convenience init(frame: CGRect, parentView: NSView?) {
        self.init(frame: frame)
        
        // 如果提供了父视图，自动配置并添加
        if let parent = parentView {
            configureAndAddToParentView(parent)
        }
    }
    
    public required init? (coder: NSCoder)
    {
        super.init (coder: coder)
        setup ()
    }

    func setup ()
    {
        terminalDelegate = self
        process = LocalProcess (delegate: self)
    }
    
    /**
     * The `processDelegate` is used to deliver messages and information relevant t
     */
    public weak var processDelegate: LocalProcessTerminalViewDelegate?
    
    // MARK: - 配置器相关方法
    
    /**
     * 将终端配置并添加到视图中，返回自身以支持链式调用
     * - Parameter view: 要添加到的父视图
     * - Parameter frame: 显示框架，如果为nil则使用父视图的bounds
     * - Parameter autoresizingMask: 自动调整掩码，默认为宽度和高度自适应
     * - Returns: 终端视图自身，用于链式调用
     */
    @discardableResult
    public func configureAndAddToParentView(_ view: NSView, frame: CGRect? = nil) -> Self {
        // 创建内部配置器
        _configurator = self.configure()
        
        // 设置布局
        _configurator?.addToViewAndConfigure(view, frame: frame)
        
        return self
    }
    
    /**
     * 设置框架大小
     * - Parameter frame: 新的框架大小
     */
    public func updateFrameSize(_ size: NSSize) {
        // 调用原始的setFrameSize方法
        super.setFrameSize(size)
        
        // 同时更新配置器的框架大小，使容器视图也跟着变化
        if let frame = self.superview?.bounds {
            _configurator?.setFrame(frame)
        }
    }
    
    /**
     * 需要重新布局
     */
    public func updateLayout() {
        _configurator?.needsLayout()
    }
    
    /**
     * 应用自定义主题
     * - Parameter theme: 要应用的主题
     */
    public func applyCustomTheme(_ theme: SwiftTerm.ThemeColor) {
        if let configurator = _configurator {
            configurator.applyTheme(theme)
        }
    }
    
    /**
     * 应用字体
     * - Parameter name: 字体名称
     * - Parameter size: 字体大小，如果为0则使用当前大小
     */
    public func applyFont(name: String, size: CGFloat = 0) {
        changingFontSize = true
        _configurator?.applyFont(name: name, size: size)
        // 设置一个延迟，确保字体更改完成后重置标志
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.changingFontSize = false
        }
    }
    
    /**
     * 启用透明背景
     * - Parameter transparent: 是否启用透明背景
     */
    public func enableTransparentBackground(_ transparent: Bool) {
        _configurator?.enableTransparentBackground(transparent)
    }
    
    /**
     * 检查是否正在进行字体大小更改
     * - Returns: 是否正在更改字体大小
     */
    public func isChangingFontSize() -> Bool {
        return self.changingFontSize
    }
    
    /**
     * This method is invoked to notify the client of the new columsn and rows that have been set by the UI
     */
    public func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        guard process.running else {
            return
        }
        var size = getWindowSize()
        let _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)
        
        processDelegate?.sizeChanged (source: self, newCols: newCols, newRows: newRows)
    }
    
    public func clipboardCopy(source: TerminalView, content: Data) {
        if let str = String (bytes: content, encoding: .utf8) {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.writeObjects([str as NSString])
        }
    }
    
    /**
     * Invoke this method to notify the processDelegate of the new title for the terminal window
     */
    public func setTerminalTitle(source: TerminalView, title: String) {
        processDelegate?.setTerminalTitle (source: self, title: title)
    }

    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        processDelegate?.hostCurrentDirectoryUpdate(source: source, directory: directory)
    }
    

    /**
     * This method is invoked when input from the user needs to be sent to the client
     * Implementation of the TerminalViewDelegate method
     */
    open func send(source: TerminalView, data: ArraySlice<UInt8>)
    {
        process.send (data: data)
    }
    
    /**
     * Use this method to toggle the logging of data coming from the host, or pass nil to stop
     */
    public func setHostLogging (directory: String?)
    {
        process.setHostLogging (directory: directory)
    }
    
    /// Implementation of the TerminalViewDelegate method
    open func scrolled(source: TerminalView, position: Double) {
        // noting
    }

    open func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        //
    }
    
    /**
     * Launches a child process inside a pseudo-terminal.
     * - Parameter executable: The executable to launch inside the pseudo terminal, defaults to /bin/bash
     * - Parameter args: an array of strings that is passed as the arguments to the underlying process
     * - Parameter environment: an array of environment variables to pass to the child process, if this is null, this picks a good set of defaults from `Terminal.getEnvironmentVariables`.
     * - Parameter execName: If provided, this is used as the Unix argv[0] parameter, otherwise, the executable is used as the args [0], this is used when the intent is to set a different process name than the file that backs it.
     */
    public func startProcess(executable: String = "/bin/bash", args: [String] = [], environment: [String]? = nil, execName: String? = nil)
    {
        process.startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }
    
    /**
     * Implements the LocalProcessDelegate method.
     */
    open func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
        processDelegate?.processTerminated(source: self, exitCode: exitCode)
    }
    
    /**
     * Implements the LocalProcessDelegate.dataReceived method
     */
    open func dataReceived(slice: ArraySlice<UInt8>) {
        feed (byteArray: slice)
    }
    
    /**
     * Implements the LocalProcessDelegate.getWindowSize method
     */
    open func getWindowSize () -> winsize
    {
        let f: CGRect = self.frame
        return winsize(ws_row: UInt16(terminal.rows), ws_col: UInt16(terminal.cols), ws_xpixel: UInt16 (f.width), ws_ypixel: UInt16 (f.height))
    }
}

#endif

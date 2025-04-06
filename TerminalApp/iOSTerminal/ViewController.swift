//
//  ViewController.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/19/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import UIKit
import SwiftTerm
import Combine
import SwiftUI

class ViewController: UIViewController, ObservableObject, TerminalViewDelegate, UIAdaptivePresentationControllerDelegate {
    var tv: TerminalView!
    var transparent: Bool = false
    
    // 设置状态
    @Published var showingSettings = false
    
    // 保存原始终端代理
    private var originalTerminalDelegate: TerminalViewDelegate?
    
    var useAutoLayout: Bool {
        get { true }
    }
    func makeFrame (keyboardDelta: CGFloat, _ fn: String = #function, _ ln: Int = #line) -> CGRect
    {
        if useAutoLayout {
            return CGRect.zero
        } else {
            return CGRect (x: view.safeAreaInsets.left,
                           y: view.safeAreaInsets.top,
                           width: view.frame.width - view.safeAreaInsets.left - view.safeAreaInsets.right,
                           height: view.frame.height - view.safeAreaInsets.top - keyboardDelta)
        }
    }
    
    func setupKeyboardMonitor ()
    {
        if #available(iOS 15.0, *), useAutoLayout {
            tv.translatesAutoresizingMaskIntoConstraints = false
            tv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            tv.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            tv.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            
            tv.keyboardLayoutGuide.topAnchor.constraint(equalTo: tv.bottomAnchor).isActive = true
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow),
                name: UIWindow.keyboardWillShowNotification,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillHide),
                name: UIWindow.keyboardWillHideNotification,
                object: nil)
        }
    }
    
    var keyboardDelta: CGFloat = 0
    @objc private func keyboardWillShow(_ notification: NSNotification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        keyboardDelta = keyboardViewEndFrame.height
        tv.frame = makeFrame(keyboardDelta: keyboardViewEndFrame.height)
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tv.frame = CGRect (origin: tv.frame.origin, size: size)
    }
    
    @objc private func keyboardWillHide(_ notification: NSNotification) {
        //let key = UIResponder.keyboardFrameBeginUserInfoKey
        keyboardDelta = 0
        tv.frame = makeFrame(keyboardDelta: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // 使用标准SshTerminalView
        tv = SshTerminalView(frame: makeFrame(keyboardDelta: 0))
        
        // 设置自己为终端视图的代理
        if let sshTerminalView = tv as? SshTerminalView {
            // 保留原有的代理
            let originalDelegate = sshTerminalView.terminalDelegate
            
            // 为终端视图设置一个新的代理链
            sshTerminalView.terminalDelegate = self
            
            // 存储原始代理，以便在需要时使用
            self.originalTerminalDelegate = originalDelegate
        }
        
        if transparent {
            let x = UIImage (contentsOfFile: "/tmp/Lucia.png")!.cgImage
            //let x = UIImage (systemName: "star")!.cgImage
            let layer = CALayer()
            tv.isOpaque = false
            tv.backgroundColor = UIColor.clear
            tv.nativeBackgroundColor = UIColor.clear
            layer.contents = x
            layer.frame = tv.bounds
            view.layer.addSublayer(layer)
        }
        
        view.addSubview(tv)
        setupKeyboardMonitor()
        
        // 设置视图
        setupSettingsButton()
        
        // 配置通知观察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemeChange),
            name: Notification.Name("ThemeChanged"),
            object: nil
        )
        
        // 请求成为第一响应者
        let _ = tv.becomeFirstResponder()
        
        // 初始化showingSettings状态
        showingSettings = false
        
        // 启用主题切换优化
        TerminalView.enableThemeSwitchImprovement()
        
        // 应用当前主题
        if let theme = themes.first(where: { $0.name == settings.themeName }) ?? themes.first {
            // 创建用于TerminalView的ThemeColor
            let terminalTheme = TerminalView.TerminalThemeColor(
                ansiColors: theme.ansi,
                foreground: theme.foreground, 
                background: theme.background,
                cursor: theme.cursor,
                selectionColor: theme.selectionColor,
                isLight: Double(theme.background.brightness) > 0.5
            )
            
            // 直接调用 SwiftTerm 的 applyTheme 方法
            tv.applyTheme(theme: terminalTheme)
        }
        
        // 应用保存的字体和字体大小
        tv.changeFontSmoothly(fontName: settings.fontName, size: settings.fontSize)
    }
    
    override func viewWillLayoutSubviews() {
        if useAutoLayout, #available(iOS 15.0, *) {
            // 使用自动布局，不需要手动设置框架
        } else {
            // 正常情况下更新整个框架
            tv.frame = makeFrame(keyboardDelta: keyboardDelta)
        }
        
        if transparent {
            tv.backgroundColor = UIColor.clear
        }
    }
    
    // MARK: - TerminalViewDelegate 协议实现
    
    func scrolled(source: TerminalView, position: Double) {
        originalTerminalDelegate?.scrolled(source: source, position: position)
    }
    
    func setTerminalTitle(source: TerminalView, title: String) {
        originalTerminalDelegate?.setTerminalTitle(source: source, title: title)
    }
    
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        originalTerminalDelegate?.send(source: source, data: data)
    }
    
    func clipboardCopy(source: TerminalView, content: Data) {
        originalTerminalDelegate?.clipboardCopy(source: source, content: content)
    }
    
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        originalTerminalDelegate?.hostCurrentDirectoryUpdate(source: source, directory: directory)
    }
    
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        originalTerminalDelegate?.rangeChanged(source: source, startY: startY, endY: endY)
    }
    
    func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        originalTerminalDelegate?.requestOpenLink(source: source, link: link, params: params)
    }
    
    func bell(source: TerminalView) {
        originalTerminalDelegate?.bell(source: source)
    }
    
    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
        originalTerminalDelegate?.iTermContent(source: source, content: content)
    }
    
    // 处理终端大小变化
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        // 如果终端视图正在更改字体大小，不进行额外处理
        if tv.isFontSizeChanging() {
            return
        }
        
        // 获取最佳尺寸
        let optimalSize = getOptimalTerminalSize()
        
        // 确保终端视图使用最佳尺寸
        DispatchQueue.main.async {
            if !self.useAutoLayout {
                // 如果不使用自动布局，手动调整视图大小
                self.tv.frame = CGRect(
                    x: self.tv.frame.origin.x,
                    y: self.tv.frame.origin.y,
                    width: optimalSize.width,
                    height: optimalSize.height
                )
            }
            
            // 强制重新布局
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
        // 将大小变化传递给原始代理
        originalTerminalDelegate?.sizeChanged(source: source, newCols: newCols, newRows: newRows)
    }
    
    // 获取终端的最佳尺寸
    func getOptimalTerminalSize() -> CGSize {
        return calculateOptimalSize(
            cols: tv.getTerminal().cols,
            rows: tv.getTerminal().rows
        )
    }
    
    // 计算指定行列数的最佳尺寸
    private func calculateOptimalSize(cols: Int, rows: Int) -> CGSize {
        // 由于无法直接访问cellDimension，我们通过计算当前视图尺寸与行列数的关系来估算
        if let terminal = tv as? SshTerminalView {
            // 获取当前视图尺寸与行列数的比例
            let currentWidth = terminal.frame.width
            let currentHeight = terminal.frame.height
            let currentCols = terminal.getTerminal().cols
            let currentRows = terminal.getTerminal().rows
            
            // 估算单元格尺寸
            let estimatedCellWidth = (currentCols > 0) ? (currentWidth / CGFloat(currentCols)) : 0
            let estimatedCellHeight = (currentRows > 0) ? (currentHeight / CGFloat(currentRows)) : 0
            
            // 计算新尺寸
            let width = CGFloat(cols) * estimatedCellWidth
            let height = CGFloat(rows) * estimatedCellHeight
            
            return CGSize(width: width, height: height)
        }
        
        return tv.frame.size
    }
    
    // MARK: - 设置功能
    
    func setupSettingsButton() {
        // 创建设置按钮
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(showSettings))
        
        // 如果是在导航控制器中，添加到导航栏
        if let navigationController = self.navigationController {
            navigationController.navigationBar.topItem?.rightBarButtonItem = settingsButton
        } else {
            // 否则创建一个悬浮按钮
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "gear"), for: .normal)
            button.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
            button.frame = CGRect(x: view.frame.width - 60, y: 40, width: 44, height: 44)
            button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            button.layer.cornerRadius = 22
            view.addSubview(button)
        }
    }
    
    // 显示设置
    @objc func showSettings() {
        showingSettings = true
        
        // 使用SwiftUI展示设置视图
        let settingsView = TerminalSettingsView(
            isPresented: Binding<Bool>(
                get: { self.showingSettings },
                set: { 
                    self.showingSettings = $0
                    if !$0 {
                        // 如果设置为false，关闭当前呈现的控制器
                        self.dismiss(animated: true)
                    }
                }
            ),
            terminal: tv as! SshTerminalView
        )
        
        let hostingController = UIHostingController(rootView: settingsView)
        hostingController.modalPresentationStyle = .formSheet
        hostingController.presentationController?.delegate = self
        present(hostingController, animated: true)
        
        // 添加对showingSettings的观察
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            if let self = self, !self.showingSettings, let presentedVC = self.presentedViewController {
                presentedVC.dismiss(animated: true)
            }
        }
        
        // 在控制器释放时移除观察者
        hostingController.didMove(toParent: self)
    }
    
    // 应用主题
    func applyTheme(themeName: String) {
        if let theme = themes.first(where: { $0.name == themeName }) ?? themes.first {
            // 创建用于TerminalView的ThemeColor
            let terminalTheme = TerminalView.TerminalThemeColor(
                ansiColors: theme.ansi,
                foreground: theme.foreground,
                background: theme.background,
                cursor: theme.cursor,
                selectionColor: theme.selectionColor,
                isLight: Double(theme.background.brightness) > 0.5
            )
            
            // 应用主题到终端视图
            tv.applyTheme(theme: terminalTheme)
        }
    }
    
    // 处理主题变更通知
    @objc func handleThemeChange(_ notification: Notification) {
        if let themeName = notification.userInfo?["themeName"] as? String {
            applyTheme(themeName: themeName)
        }
    }
    
    // 处理设置视图消失
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 如果当前没有呈现的视图控制器，更新showingSettings状态
        if presentedViewController == nil {
            showingSettings = false
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // 当用户通过下滑手势关闭弹窗时更新状态
        showingSettings = false
    }
}


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
    var configurator: TerminalConfigurator!
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
    
    // 为容器视图计算正确的框架，考虑到它必须比终端视图更大以容纳内边距
    func makeContainerFrame(keyboardDelta: CGFloat) -> CGRect {
        let frame = makeFrame(keyboardDelta: keyboardDelta)
        
        // 检查是否使用了容器视图
        if view.subviews.first(where: { $0 is TerminalContainerView }) != nil {
            return frame
        }
        
        return frame
    }
    
    func setupKeyboardMonitor ()
    {
        if #available(iOS 15.0, *), useAutoLayout {
            // 查找容器视图
            if let containerView = view.subviews.first(where: { $0 is TerminalContainerView }) {
                containerView.translatesAutoresizingMaskIntoConstraints = false
                containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
                containerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
                
                containerView.keyboardLayoutGuide.topAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
            } else {
                // 如果没有找到容器视图，则直接配置终端视图（兼容旧代码）
                tv.translatesAutoresizingMaskIntoConstraints = false
                tv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                tv.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
                tv.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
                
                tv.keyboardLayoutGuide.topAnchor.constraint(equalTo: tv.bottomAnchor).isActive = true
            }
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
        
        if view.subviews.first(where: { $0 is TerminalContainerView }) != nil {
            // 使用配置器调整容器框架
            configurator.setFrame(makeFrame(keyboardDelta: keyboardViewEndFrame.height))
        } else {
            // 如果没有找到容器视图，则直接调整终端视图（兼容旧代码）
            tv.frame = makeFrame(keyboardDelta: keyboardViewEndFrame.height)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: NSNotification) {
        keyboardDelta = 0
        
        if view.subviews.first(where: { $0 is TerminalContainerView }) != nil {
            // 使用配置器调整容器框架
            configurator.setFrame(makeFrame(keyboardDelta: 0))
        } else {
            // 如果没有找到容器视图，则直接调整终端视图（兼容旧代码）
            tv.frame = makeFrame(keyboardDelta: 0)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let _ = view.subviews.first(where: { $0 is TerminalContainerView }) {
            // 使用配置器调整容器框架
            configurator.setFrame(CGRect(origin: CGPoint.zero, size: size))
        } else {
            // 如果没有找到容器视图，则直接调整终端视图（兼容旧代码）
            tv.frame = CGRect(origin: tv.frame.origin, size: size)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // 使用标准SshTerminalView
        tv = SshTerminalView(frame: makeFrame(keyboardDelta: 0))
        
        // 设置自己为终端视图的代理
        if let sshTerminalView = tv as? SshTerminalView {
            // 保留原有的代理
            originalTerminalDelegate = sshTerminalView.terminalDelegate
            
            // 设置终端代理
            sshTerminalView.terminalDelegate = self
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
        
        // 创建配置器并一步添加到视图
        configurator = tv.configureAndAddToView(view, frame: makeFrame(keyboardDelta: 0))
        
        // 设置透明度
        if transparent {
            configurator.enableTransparentBackground(true)
        }
        
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
            // 创建一个SwiftTerm.ThemeColor对象
            let swiftTermTheme = SwiftTerm.ThemeColor(
                name: theme.name,
                ansi: theme.ansi,
                background: theme.background,
                foreground: theme.foreground,
                cursor: theme.cursor,
                cursorText: theme.cursorText,
                selectedText: theme.selectedText,
                selectionColor: theme.selectionColor
            )
            
            // 使用配置器应用主题
            configurator.applyTheme(swiftTermTheme)
        }
        
        // 应用保存的字体和字体大小
        configurator.applyFont(name: settings.fontName, size: settings.fontSize)
    }
    
    override func viewWillLayoutSubviews() {
        if useAutoLayout, #available(iOS 15.0, *) {
            // 使用自动布局，不需要手动设置框架
        } else {
            if let _ = view.subviews.first(where: { $0 is TerminalContainerView }) {
                // 使用配置器调整容器框架
                configurator.setFrame(makeFrame(keyboardDelta: keyboardDelta))
                
                // 强制终端视图重新绘制
                DispatchQueue.main.async {
                    self.tv.setNeedsDisplay(self.tv.bounds)
                }
            } else {
                // 如果没有找到容器视图，则直接调整终端视图（兼容旧代码）
                tv.frame = makeFrame(keyboardDelta: keyboardDelta)
            }
        }
        
        if transparent {
            configurator.enableTransparentBackground(true)
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
        print("TerminalViewDelegate.sizeChanged: \(newCols) x \(newRows)")
        
        // 如果终端视图正在更改字体大小，不进行额外处理
        if tv.isFontSizeChanging() {
            print("字体大小正在变更中，延迟处理终端尺寸变化")
            
            // 将大小变化传递给原始代理
            originalTerminalDelegate?.sizeChanged(source: source, newCols: newCols, newRows: newRows)
            
            // 标记稍后需要进行布局刷新（稍微延迟处理，确保完成字体计算）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateTerminalSize()
                
                // 完成后，再次刷新以确保内容正确显示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("字体大小变更后，再次刷新终端显示")
                    
                    // 在容器视图或终端视图上强制刷新
                    if let containerView = self.view.subviews.first(where: { $0 is TerminalContainerView }) {
                        containerView.setNeedsLayout()
                        containerView.layoutIfNeeded()
                    }
                    
                    // 刷新视图，让终端控制自己的显示
                    self.tv.setNeedsDisplay(self.tv.bounds)
                    
                    // 确保配置器重新同步
                    self.configurator.refreshDisplay()
                    
                    print("完成终端尺寸调整，新尺寸: \(self.tv.getTerminal().cols) x \(self.tv.getTerminal().rows)")
                }
            }
            return
        }
        
        print("常规终端尺寸变化处理")
        
        // 计算可用视图尺寸
        let viewWidth = self.view.bounds.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right
        let viewHeight = self.view.bounds.height - self.view.safeAreaInsets.top - self.keyboardDelta
        
        // 确保终端视图使用合适尺寸
        DispatchQueue.main.async {
            if !self.useAutoLayout {
                // 如果不使用自动布局，调整容器或终端视图
                if let containerView = self.view.subviews.first(where: { $0 is TerminalContainerView }) {
                    containerView.frame = CGRect(
                        x: self.view.safeAreaInsets.left,
                        y: self.view.safeAreaInsets.top,
                        width: viewWidth,
                        height: viewHeight
                    )
                } else {
                    self.tv.frame = CGRect(
                        x: self.view.safeAreaInsets.left,
                        y: self.view.safeAreaInsets.top,
                        width: viewWidth,
                        height: viewHeight
                    )
                }
            }
            
            // 强制重新布局
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            // 手动刷新容器和终端视图
            self.updateTerminalSize()
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
    func applyTheme(_ name: String) {
        // 找到主题
        if let theme = themes.first(where: { $0.name == name }) ?? themes.first {
            print("ViewController: 开始应用主题: \(name)")
            
            // 创建一个SwiftTerm.ThemeColor对象
            let swiftTermTheme = SwiftTerm.ThemeColor(
                name: theme.name,
                ansi: theme.ansi,
                background: theme.background,
                foreground: theme.foreground,
                cursor: theme.cursor,
                cursorText: theme.cursorText,
                selectedText: theme.selectedText,
                selectionColor: theme.selectionColor
            )
            
            // 使用配置器应用主题
            configurator.applyTheme(swiftTermTheme)
            
            print("ViewController: 应用主题后终端背景色: \(tv.backgroundColor ?? UIColor.clear)")
            
            // 根据透明模式设置容器视图背景色
            if !transparent {
                configurator.syncContainerBackgroundColor()
            } else {
                configurator.enableTransparentBackground(true)
            }
            
            print("ViewController: 容器背景色设置完成")
            
            // 保存主题名
            UserDefaults.standard.set(name, forKey: "lastTheme")
        }
    }
    
    // 处理主题变更通知
    @objc func handleThemeChange(_ notification: Notification) {
        if let themeName = notification.userInfo?["themeName"] as? String {
            print("ViewController: 收到主题变更通知: \(themeName)")
            
            // 应用主题
            applyTheme(themeName)
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
    
    // 手动更新终端尺寸
    func updateTerminalSize() {
        // 强制终端视图刷新布局
        DispatchQueue.main.async {
            // 如果终端视图在字体变化中，先等一会再更新
            if self.tv.isFontSizeChanging() {
                print("字体大小正在变更中，延迟更新布局")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateTerminalSize()
                }
                return
            }
            
            print("开始更新终端尺寸")
            
            // 先重新计算行列数
            let terminalCols = self.tv.getTerminal().cols
            let terminalRows = self.tv.getTerminal().rows
            
            // 获取当前视图尺寸
            let viewWidth = self.view.bounds.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right
            let viewHeight = self.view.bounds.height - self.view.safeAreaInsets.top - self.keyboardDelta
            
            print("当前可用视图尺寸: \(viewWidth) x \(viewHeight)")
            print("当前终端行列数: \(terminalCols) x \(terminalRows)")
            
            // 获取最佳尺寸 - 基于当前字体的单元格大小
            let optimalSize = self.getOptimalTerminalSize()
            print("计算的最佳终端尺寸: \(optimalSize.width) x \(optimalSize.height)")
            
            // 显式使用TerminalConfigurator调整终端视图
            if let containerView = self.view.subviews.first(where: { $0 is TerminalContainerView }) as? TerminalContainerView {
                print("使用容器视图调整尺寸")
                
                // 如果不使用自动布局，手动调整容器视图大小
                if !self.useAutoLayout {
                    containerView.frame = CGRect(
                        x: self.view.safeAreaInsets.left,
                        y: self.view.safeAreaInsets.top,
                        width: viewWidth,
                        height: viewHeight
                    )
                }
                
                // 刷新容器视图
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
            } else if !self.useAutoLayout {
                // 如果没有容器视图，直接调整终端视图大小
                print("直接调整终端视图尺寸")
                self.tv.frame = CGRect(
                    x: self.view.safeAreaInsets.left,
                    y: self.view.safeAreaInsets.top,
                    width: viewWidth,
                    height: viewHeight
                )
            }
            
            // 使用配置器刷新显示
            print("使用配置器刷新显示")
            self.configurator.refreshDisplay()
            
            // 确保显示准确，稍后强制重绘
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // 请求首次响应者，确保正确处理输入
                _ = self.tv.becomeFirstResponder()
                
                // 通过scrollPosition触发内容重绘
                if self.tv.canScroll {
                    let position = self.tv.scrollPosition
                    self.scrolled(source: self.tv, position: position)
                }
                
                // 强制终端视图重新绘制
                print("强制终端视图重新绘制")
                self.tv.setNeedsDisplay(self.tv.bounds)
                
                // 再次刷新，确保内容完全更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.configurator.refreshDisplay()
                    self.tv.setNeedsDisplay(self.tv.bounds)
                    
                    print("终端尺寸更新完成")
                    print("更新后终端行列数: \(self.tv.getTerminal().cols) x \(self.tv.getTerminal().rows)")
                    print("更新后终端视图尺寸: \(self.tv.frame.width) x \(self.tv.frame.height)")
                }
            }
        }
    }
    
    // 处理字体变更
    func applyFont(name: String, size: CGFloat) {
        print("应用字体变更: \(name), 大小: \(size)")
        
        // 在字体变更前保存当前终端状态信息
        let isAltBuffer = !self.tv.canScroll
        let scrollPosition = self.tv.scrollPosition
        
        // 设置字体
        configurator.applyFont(name: name, size: size)
        
        // 等待字体变更完成后调整内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 强制刷新容器
            self.configurator.refreshDisplay()
            
            // 如果不是替代缓冲区且可以滚动，尝试恢复滚动位置
            if !isAltBuffer && self.tv.canScroll {
                print("恢复滚动位置: \(scrollPosition)")
                self.scrolled(source: self.tv, position: scrollPosition)
            }
            
            // 额外进行一次完整的布局更新
            self.updateTerminalSize()
            
            // 再次更新显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let containerView = self.view.subviews.first(where: { $0 is TerminalContainerView }) {
                    containerView.setNeedsLayout()
                }
                self.tv.setNeedsDisplay(self.tv.bounds)
                
                print("字体变更完成，新终端尺寸: \(self.tv.getTerminal().cols) x \(self.tv.getTerminal().rows)")
            }
        }
    }
}


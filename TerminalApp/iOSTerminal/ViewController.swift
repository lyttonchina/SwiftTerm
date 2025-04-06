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
    var containerView: TerminalContainerView!
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
        
        // 如果使用了容器视图且找到了它，需要确保容器尺寸正确
        if let _ = view.subviews.first(where: { $0 is TerminalContainerView }) as? TerminalContainerView {
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
        
        // 查找容器视图并调整其位置
        if let containerView = view.subviews.first(where: { $0 is TerminalContainerView }) {
            containerView.frame = makeFrame(keyboardDelta: keyboardViewEndFrame.height)
        } else {
            // 如果没有找到容器视图，则直接调整终端视图（兼容旧代码）
            tv.frame = makeFrame(keyboardDelta: keyboardViewEndFrame.height)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: NSNotification) {
        //let key = UIResponder.keyboardFrameBeginUserInfoKey
        keyboardDelta = 0
        
        // 查找容器视图并调整其位置
        if let containerView = view.subviews.first(where: { $0 is TerminalContainerView }) {
            containerView.frame = makeFrame(keyboardDelta: 0)
        } else {
            // 如果没有找到容器视图，则直接调整终端视图（兼容旧代码）
            tv.frame = makeFrame(keyboardDelta: 0)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // 查找容器视图并调整其尺寸
        if let containerView = view.subviews.first(where: { $0 is TerminalContainerView }) {
            containerView.frame = CGRect(origin: containerView.frame.origin, size: size)
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
        
        // 创建一个容器视图，它在终端视图周围提供简单的边距
        let containerView = tv.withContainer()
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 确保容器有正确的背景色
        print("ViewDidLoad: 终端视图的backgroundColor: \(tv.backgroundColor ?? UIColor.clear)")
        
        // 根据透明模式设置容器视图背景色
        if !transparent {
            containerView.backgroundColor = tv.backgroundColor
        } else {
            containerView.backgroundColor = UIColor.clear
        }
        print("ViewDidLoad: 设置容器背景色为: \(containerView.backgroundColor ?? UIColor.clear)")
        
        // 将容器视图添加到视图层次结构
        view.addSubview(containerView)
        
        // 保存对容器视图的引用
        self.containerView = containerView
        
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
            // 查找容器视图并调整其位置
            if let containerView = view.subviews.first(where: { $0 is TerminalContainerView }) {
                containerView.frame = makeFrame(keyboardDelta: keyboardDelta)
                
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
            // 标记稍后需要进行布局刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.updateTerminalSize()
            }
            
            // 将大小变化传递给原始代理
            originalTerminalDelegate?.sizeChanged(source: source, newCols: newCols, newRows: newRows)
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
            
            // 创建用于TerminalView的ThemeColor
            let terminalTheme = TerminalView.TerminalThemeColor(
                ansiColors: theme.ansi,
                foreground: theme.foreground,
                background: theme.background,
                cursor: theme.cursor,
                selectionColor: theme.selectionColor,
                isLight: Double(theme.background.brightness) > 0.5
            )
            
            // 应用主题
            tv.applyTheme(theme: terminalTheme)
            
            print("ViewController: 应用主题后终端背景色: \(tv.backgroundColor ?? UIColor.clear)")
            
            // 根据透明模式设置容器视图背景色
            if !transparent {
                containerView.backgroundColor = tv.backgroundColor
            } else {
                containerView.backgroundColor = UIColor.clear
            }
            
            print("ViewController: 容器背景色设置完成: \(containerView.backgroundColor ?? UIColor.clear)")
            
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
            
            // 根据透明模式设置容器视图背景色
            if !transparent {
                containerView.backgroundColor = tv.backgroundColor
            } else {
                containerView.backgroundColor = UIColor.clear
            }
            
            print("ViewController: 主题变更通知中设置容器背景色: \(containerView.backgroundColor ?? UIColor.clear)")
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateTerminalSize()
                }
                return
            }
            
            // 强制容器视图刷新
            if let containerView = self.view.subviews.first(where: { $0 is TerminalContainerView }) {
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
            }
            
            // 强制终端视图重新绘制
            self.tv.setNeedsDisplay(self.tv.bounds)
        }
    }
}


//
//  TerminalContainerView.swift
//
//  Created to add a container around terminal views with customizable margins
//

#if os(iOS) || os(visionOS) || os(macOS)
import Foundation
#if os(iOS) || os(visionOS)
import UIKit
public typealias TTView = UIView
public typealias EdgeInsets = UIEdgeInsets
#else
import AppKit
public typealias TTView = NSView
public typealias EdgeInsets = NSEdgeInsets
#endif

/// A container view that wraps a terminal view and provides margins
public class TerminalContainerView: TTView {
    /// The terminal view that this container contains
    public let terminalView: TerminalView
    
    /// The insets around the terminal view
    public let insets: EdgeInsets
    
    #if os(macOS)
    /// The background color of the container view (macOS version)
    private var _backgroundColor: NSColor = NSColor.clear
    
    /// The background color of the container view (macOS version)
    public var backgroundColor: NSColor {
        get { return _backgroundColor }
        set { 
            _backgroundColor = newValue
            // 确保背景色变更时更新layer
            if self.layer == nil {
                self.wantsLayer = true
            }
            self.layer?.backgroundColor = newValue.cgColor
            self.needsDisplay = true
            print("TerminalContainerView: 背景色已设置为 \(newValue)")
        }
    }
    
    /// 直接设置背景色而不打印日志，用于避免主题切换时的闪烁
    public func setBackgroundColorSilently(_ color: NSColor) {
        _backgroundColor = color
        if self.layer == nil {
            self.wantsLayer = true
        }
        self.layer?.backgroundColor = color.cgColor
        self.needsDisplay = true
    }
    
    public override var wantsUpdateLayer: Bool {
        return true
    }
    
    public override func updateLayer() {
        super.updateLayer()
        print("TerminalContainerView.updateLayer: 设置layer背景色为 \(_backgroundColor)")
        if self.layer == nil {
            self.wantsLayer = true
        }
        layer?.backgroundColor = _backgroundColor.cgColor
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        print("TerminalContainerView.draw: 绘制背景色 \(_backgroundColor)")
        _backgroundColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // 视图添加到窗口时，确保背景色正确
        syncBackgroundColor()
    }
    
    public override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        // 视图添加到父视图时，确保背景色正确
        syncBackgroundColor()
    }
    #endif
    
    /// Initializes a container view around the given terminal view with specified insets
    /// - Parameters:
    ///   - terminalView: The terminal view to contain
    ///   - insets: The insets around the terminal view
    public init(terminalView: TerminalView, insets: EdgeInsets) {
        self.terminalView = terminalView
        self.insets = insets
        
        #if os(iOS) || os(visionOS)
        super.init(frame: .zero)
        #else
        super.init(frame: .zero)
        wantsLayer = true
        #endif
        
        addSubview(terminalView)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 确保终端视图正确布局在容器中
    private func setupLayout() {
        #if os(iOS) || os(visionOS)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: terminalView.bottomAnchor, constant: insets.bottom),
            trailingAnchor.constraint(equalTo: terminalView.trailingAnchor, constant: insets.right)
        ])
        #else
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: terminalView.bottomAnchor, constant: insets.bottom),
            trailingAnchor.constraint(equalTo: terminalView.trailingAnchor, constant: insets.right)
        ])
        #endif
    }
    
    /// 同步背景颜色与终端视图
    public func syncBackgroundColor() {
        #if os(iOS) || os(visionOS)
        if let terminalBgColor = terminalView.backgroundColor {
            self.backgroundColor = terminalBgColor
            print("iOS终端容器: 同步背景色为 \(terminalBgColor)")
        } else {
            print("iOS终端容器: 终端背景色为nil")
        }
        #else
        // macOS版本获取终端背景色
        let bgColor = terminalView.nativeBackgroundColor
        
        // 确保使用统一的颜色空间进行转换
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        bgColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let convertedColor = NSColor(srgbRed: r, green: g, blue: b, alpha: a)
        self.backgroundColor = convertedColor
        print("macOS终端容器: 同步背景色，原始色为 \(bgColor)，转换后为 \(convertedColor)")
        
        // 确保layer存在并设置背景色
        if self.layer == nil {
            self.wantsLayer = true
        }
        self.layer?.backgroundColor = convertedColor.cgColor
        
        // 强制重绘
        self.needsDisplay = true
        
        // 强制更新该层
        self.forceUpdate()
        #endif
    }
    
    /// 强制更新视图显示
    public func forceUpdate() {
        #if os(iOS) || os(visionOS)
        self.setNeedsDisplay()
        #else
        // 确保窗口和视图存在
        guard let window = self.window else {
            return
        }
        
        // 标记为需要显示
        self.needsDisplay = true
        
        // 立即更新
        window.displayIfNeeded()
        
        // 强制视图刷新
        if let layer = self.layer {
            layer.setNeedsDisplay()
            layer.displayIfNeeded()
        }
        
        // 如果有分层，递归更新子视图
        for subview in self.subviews {
            subview.needsDisplay = true
        }
        #endif
    }
    
    // 重写调整大小方法，确保终端视图在容器中正确调整大小
    #if os(macOS)
    public override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        updateTerminalFrame()
    }
    #else
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateTerminalFrame()
    }
    #endif
    
    private func updateTerminalFrame() {
        #if os(iOS) || os(visionOS)
        let newFrame = bounds.inset(by: insets)
        if terminalView.frame != newFrame {
            terminalView.frame = newFrame
        }
        #else
        let newFrame = NSRect(
            x: insets.left,
            y: insets.top,
            width: bounds.width - insets.left - insets.right,
            height: bounds.height - insets.top - insets.bottom
        )
        if terminalView.frame != newFrame {
            terminalView.frame = newFrame
        }
        #endif
    }
}
#endif 

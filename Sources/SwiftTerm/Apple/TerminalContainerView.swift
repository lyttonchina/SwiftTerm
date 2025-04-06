//
//  TerminalContainerView.swift
//
//  Created to add a container around terminal views with customizable margins
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation

#if os(macOS)
import AppKit
public typealias PlatformView = NSView
public typealias EdgeInsets = NSEdgeInsets
#elseif os(iOS) || os(visionOS)
import UIKit
public typealias PlatformView = UIView
public typealias EdgeInsets = UIEdgeInsets
#endif

/// A container view that wraps a terminal view and provides configurable margins
public class TerminalContainerView: PlatformView {
    /// The wrapped terminal view
    public let terminalView: PlatformView
    
    /// The insets applied to the terminal view
    public var contentInsets: EdgeInsets {
        didSet {
            updateTerminalFrame()
        }
    }
    
    /// Creates a new container view with the specified terminal view and insets
    /// - Parameters:
    ///   - terminalView: The terminal view to wrap
    ///   - insets: The insets to apply to the terminal view (default is 8pt on all sides)
    public init(terminalView: PlatformView, insets: EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)) {
        self.terminalView = terminalView
        self.contentInsets = insets
        
        #if os(macOS)
        super.init(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.wantsLayer = true
        #elseif os(iOS) || os(visionOS)
        super.init(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        #endif
        
        addSubview(terminalView)
        updateTerminalFrame()
        
        // 初始化时同步背景色
        syncBackgroundColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 同步容器视图与终端视图的背景色
    public func syncBackgroundColor() {
        #if os(iOS) || os(visionOS)
        if let tv = terminalView as? TerminalView {
            print("TerminalContainerView: 尝试同步背景色，终端背景色: \(tv.backgroundColor ?? UIColor.clear)")
            // 如果背景色是透明的，保持容器也透明
            if tv.backgroundColor == UIColor.clear {
                self.backgroundColor = UIColor.clear
            } else {
                // 如果终端背景色是有色的，则使用该颜色
                self.backgroundColor = tv.backgroundColor
                
                // 确保背景色不是 nil，如果是则设置默认黑色背景
                if self.backgroundColor == nil {
                    self.backgroundColor = UIColor.black
                    print("TerminalContainerView: 终端背景色为 nil，设置默认黑色背景")
                }
            }
            print("TerminalContainerView: 同步后容器背景色: \(self.backgroundColor ?? UIColor.clear)")
        } else {
            print("TerminalContainerView: 无法从终端获取背景色，找不到 TerminalView 实例")
            // 设置默认背景色
            self.backgroundColor = UIColor.black
        }
        #elseif os(macOS)
        if let tv = terminalView as? TerminalView {
            if let bgColor = tv.layer?.backgroundColor {
                self.layer?.backgroundColor = bgColor
                print("TerminalContainerView: macOS 同步背景色成功")
            } else {
                print("TerminalContainerView: macOS 终端背景色为 nil")
                // 设置默认背景色
                self.layer?.backgroundColor = NSColor.black.cgColor
            }
        }
        #endif
    }
    
    private func updateTerminalFrame() {
        #if os(iOS) || os(visionOS)
        let availableWidth = bounds.width - contentInsets.left - contentInsets.right
        let availableHeight = bounds.height - contentInsets.top - contentInsets.bottom
        
        terminalView.frame = CGRect(
            x: contentInsets.left,
            y: contentInsets.top,
            width: max(0, availableWidth),
            height: max(0, availableHeight)
        )
        #elseif os(macOS)
        let availableWidth = bounds.width - contentInsets.left - contentInsets.right
        let availableHeight = bounds.height - contentInsets.top - contentInsets.bottom
        
        terminalView.frame = CGRect(
            x: contentInsets.left,
            y: contentInsets.top,
            width: max(0, availableWidth),
            height: max(0, availableHeight)
        )
        #endif
    }
    
    #if os(iOS) || os(visionOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateTerminalFrame()
        
        // 布局变化时同步背景色
        syncBackgroundColor()
    }
    #endif
    
    #if os(macOS)
    public override func layout() {
        super.layout()
        updateTerminalFrame()
        
        // 布局变化时同步背景色
        syncBackgroundColor()
    }
    
    public override var frame: NSRect {
        didSet {
            updateTerminalFrame()
        }
    }
    
    public override var bounds: NSRect {
        didSet {
            updateTerminalFrame()
        }
    }
    #endif
}
#endif 
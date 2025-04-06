//
//  TerminalContainerView.swift
//
//  Created to add a container around terminal views with customizable margins
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
import CoreGraphics

#if os(iOS) || os(visionOS)
import UIKit
public typealias ContainerView = UIView
#endif

#if os(macOS)
import AppKit
public typealias ContainerView = NSView
#endif

/// A container view that wraps a terminal view and provides configurable margins
public class TerminalContainerView: ContainerView {
    /// The wrapped terminal view
    public var terminalView: ContainerView
    
    /// The insets applied to the terminal view
    public var contentInsets: NSDirectionalEdgeInsets {
        didSet {
            updateTerminalFrame()
        }
    }
    
    /// Creates a new container view with the specified terminal view and insets
    /// - Parameters:
    ///   - terminalView: The terminal view to wrap
    ///   - insets: The insets to apply to the terminal view (default is 8pt on all sides)
    public init(terminalView: ContainerView, insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)) {
        self.terminalView = terminalView
        self.contentInsets = insets
        
        super.init(frame: terminalView.frame)
        
        #if os(macOS)
        self.wantsLayer = true
        #endif
        
        addSubview(terminalView)
        updateTerminalFrame()
        
        // 设置背景色与终端视图相同
        #if os(iOS) || os(visionOS)
        if let tv = terminalView as? TerminalView {
            self.backgroundColor = tv.backgroundColor
        }
        #endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateTerminalFrame() {
        let availableWidth = bounds.width - contentInsets.leading - contentInsets.trailing
        let availableHeight = bounds.height - contentInsets.top - contentInsets.bottom
        
        terminalView.frame = CGRect(
            x: contentInsets.leading,
            y: contentInsets.top,
            width: max(0, availableWidth),
            height: max(0, availableHeight)
        )
    }
    
    #if os(iOS) || os(visionOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateTerminalFrame()
    }
    #endif
    
    #if os(macOS)
    public override func layout() {
        super.layout()
        updateTerminalFrame()
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
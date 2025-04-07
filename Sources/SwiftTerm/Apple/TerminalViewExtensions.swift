//
//  TerminalViewExtensions.swift
//  SwiftTerm
//
//  Created by 李政 on 2025/4/7.
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension TerminalView {
    /// 获取此终端的最佳尺寸
    public func getOptimalSize() -> CGSize {
        let cols = terminal.cols
        let rows = terminal.rows
        
        return CGSize(
            width: CGFloat(cols) * cellDimension.width,
            height: CGFloat(rows) * cellDimension.height
        )
    }
        
    /// 创建并配置终端
    public func configure() -> TerminalConfigurator {
        return TerminalConfigurator(terminalView: self)
    }
    
    /// 创建配置器并一步添加到视图中
    /// - Parameters:
    ///   - view: 要添加到的父视图
    ///   - frame: 显示框架，如果为nil则使用父视图的bounds
    ///   - autoresizingMask: 自动调整掩码，默认为宽度和高度自适应
    /// - Returns: 配置好的终端配置器
    public func configureAndAddToView(_ view: TTView, frame: CGRect? = nil, autoresizingMask: TTView.AutoresizingMask = [.width, .height]) -> TerminalConfigurator {
        let configurator = configure()
        configurator.addToViewAndConfigure(view, frame: frame, autoresizingMask: autoresizingMask)
        return configurator
    }
    
    /// 创建带键盘适配的终端配置器
    #if os(iOS) || os(visionOS)
    public func configureWithKeyboard() -> (configurator: TerminalConfigurator, keyboardAdapter: KeyboardAdapter) {
        let configurator = TerminalConfigurator(terminalView: self)
        let keyboardAdapter = KeyboardAdapter(terminalView: self, containerView: configurator.containerView)
        return (configurator, keyboardAdapter)
    }
    #endif
    
    /// 计算指定行列数的最佳尺寸
    public func calculateOptimalSize(cols: Int, rows: Int) -> CGSize {
        return CGSize(
            width: CGFloat(cols) * cellDimension.width,
            height: CGFloat(rows) * cellDimension.height
        )
    }
}
#endif

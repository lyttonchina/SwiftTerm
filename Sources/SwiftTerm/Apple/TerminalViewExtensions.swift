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
    
    /// 使用代理链来管理多个代理
    public func useMultipleDelegates() -> TerminalDelegateChain {
        let chain = TerminalDelegateChain()
        
        // 保存当前代理
        if let currentDelegate = terminalDelegate {
            chain.add(delegate: currentDelegate)
        }
        
        // 设置链为新代理
        terminalDelegate = chain
        
        return chain
    }
    
    /// 创建并配置终端
    public func configure() -> TerminalConfigurator {
        return TerminalConfigurator(terminalView: self)
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

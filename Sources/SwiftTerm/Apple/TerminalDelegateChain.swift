//
//  TerminalDelegateChain.swift
//  SwiftTerm
//
//  Created by 李政 on 2025/4/7.
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation

/// 终端代理链，允许多个代理接收终端事件
public class TerminalDelegateChain: TerminalViewDelegate {
    private var delegates: [TerminalViewDelegate] = []
    
    public init() {}
    
    public func add(delegate: TerminalViewDelegate) {
        if !delegates.contains(where: { $0 === delegate }) {
            delegates.append(delegate)
        }
    }
    
    public func remove(delegate: TerminalViewDelegate) {
        delegates.removeAll(where: { $0 === delegate })
    }
    
    // 实现TerminalViewDelegate协议，转发所有事件
    public func scrolled(source: TerminalView, position: Double) {
        delegates.forEach { $0.scrolled(source: source, position: position) }
    }
    
    public func setTerminalTitle(source: TerminalView, title: String) {
        delegates.forEach { $0.setTerminalTitle(source: source, title: title) }
    }
    
    public func send(source: TerminalView, data: ArraySlice<UInt8>) {
        delegates.forEach { $0.send(source: source, data: data) }
    }
    
    public func clipboardCopy(source: TerminalView, content: Data) {
        delegates.forEach { $0.clipboardCopy(source: source, content: content) }
    }
    
    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        delegates.forEach { $0.hostCurrentDirectoryUpdate(source: source, directory: directory) }
    }
    
    public func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        delegates.forEach { $0.rangeChanged(source: source, startY: startY, endY: endY) }
    }
    
    public func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        delegates.forEach { $0.requestOpenLink(source: source, link: link, params: params) }
    }
    
    public func bell(source: TerminalView) {
        delegates.forEach { $0.bell(source: source) }
    }
    
    public func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
        delegates.forEach { $0.iTermContent(source: source, content: content) }
    }
    
    public func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        delegates.forEach { $0.sizeChanged(source: source, newCols: newCols, newRows: newRows) }
    }
}
#endif

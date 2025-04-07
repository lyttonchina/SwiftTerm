//
//  KeyboardAdapter.swift
//  SwiftTerm
//
//  Created by 李政 on 2025/4/7.
//

#if os(iOS) || os(visionOS)
import UIKit

/// iOS 键盘适配器，处理键盘显示和隐藏时的布局调整
public class KeyboardAdapter {
    private weak var terminalView: TerminalView?
    private weak var containerView: TerminalContainerView?
    private var keyboardDelta: CGFloat = 0
    
    public init(terminalView: TerminalView, containerView: TerminalContainerView) {
        self.terminalView = terminalView
        self.containerView = containerView
        setupKeyboardMonitor()
    }
    
    private func setupKeyboardMonitor() {
        if #available(iOS 15.0, *) {
            setupAutoLayoutForKeyboard()
        } else {
            setupNotificationsForKeyboard()
        }
    }
    
    @available(iOS 15.0, *)
    private func setupAutoLayoutForKeyboard() {
        guard let containerView = containerView,
              let superview = containerView.superview else { return }
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor),
            containerView.leftAnchor.constraint(equalTo: superview.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: superview.rightAnchor),
            containerView.keyboardLayoutGuide.topAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupNotificationsForKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIWindow.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIWindow.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: NSNotification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let containerView = containerView,
              let superview = containerView.superview else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = superview.convert(keyboardScreenEndFrame, from: superview.window)
        keyboardDelta = keyboardViewEndFrame.height
        
        // 调整容器视图
        containerView.frame = CGRect(
            x: superview.safeAreaInsets.left,
            y: superview.safeAreaInsets.top,
            width: superview.frame.width - superview.safeAreaInsets.left - superview.safeAreaInsets.right,
            height: superview.frame.height - superview.safeAreaInsets.top - keyboardDelta
        )
    }
    
    @objc private func keyboardWillHide(_ notification: NSNotification) {
        guard let containerView = containerView,
              let superview = containerView.superview else { return }
        
        keyboardDelta = 0
        
        // 调整容器视图
        containerView.frame = CGRect(
            x: superview.safeAreaInsets.left,
            y: superview.safeAreaInsets.top,
            width: superview.frame.width - superview.safeAreaInsets.left - superview.safeAreaInsets.right,
            height: superview.frame.height - superview.safeAreaInsets.top
        )
    }
    
    // 获取当前键盘高度
    public func getKeyboardHeight() -> CGFloat {
        return keyboardDelta
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
#endif

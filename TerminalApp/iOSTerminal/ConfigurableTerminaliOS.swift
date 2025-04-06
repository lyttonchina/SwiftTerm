//
//  ConfigurableTerminaliOS.swift
//  SwiftTermApp
//
//  Created based on the macOS version
//  Copyright © 2025 sunrise. All rights reserved.
//

#if os(iOS)
import SwiftUI
import SwiftTerm
import Combine
import UIKit

struct RunningTerminalConfig: View {
    @Binding var showingModal: Bool
    var terminal: SshTerminalView
    @State var style: String = settings.themeName
    @State var fontName: String = settings.fontName
    @State var fontSize: CGFloat = settings.fontSize

    func save() {
        settings.themeName = style
        settings.fontName = fontName
        settings.fontSize = fontSize
        
        // 获取当前的 ViewController 实例并应用设置
        if let viewController = UIApplication.shared.windows.first?.rootViewController as? ViewController {
            // 应用主题
            if let theme = themes.first(where: { $0.name == style }) ?? themes.first {
                let terminalTheme = TerminalView.TerminalThemeColor(
                    ansiColors: theme.ansi,
                    foreground: theme.foreground, 
                    background: theme.background,
                    cursor: theme.cursor,
                    selectionColor: theme.selectionColor,
                    isLight: Double(theme.background.brightness) > 0.5
                )
                viewController.tv.applyTheme(theme: terminalTheme)
            }
            
            // 更新字体和字体大小
            viewController.tv.changeFontSmoothly(fontName: fontName, size: fontSize)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // 主题选择
                Section {
                    VStack(alignment: .leading) {
                        Text("主题选择")
                            .font(.headline)
                        
                        Text("在下方区域滑动或使用滚动条查看更多主题")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 主题滚动列表
                        ThemeScrollView(
                            themes: themes,
                            selectedTheme: $style
                        )
                    }
                }
                
                // 字体
                Section {
                    FontSelector(fontName: $fontName)
                        // 移除实时预览
                        //.onReceive(Just(fontName)) { newFont in
                        //    // 实时预览字体变化
                        //    terminal.changeFontSmoothly(fontName: newFont, size: fontSize)
                        //}
                }
                
                // 字体大小
                Section {
                    FontSizeSelector(fontName: fontName, fontSize: $fontSize)
                        // 移除实时预览
                        //.onReceive(Just(fontSize)) { newSize in
                        //    // 实时预览字体大小变化
                        //    terminal.changeFontSizeSmoothly(newSize)
                        //}
                }
                
                // 添加提示信息
                Section {
                    Text("字体和字体大小将在保存后应用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitle("终端设置", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    self.showingModal = false
                    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                },
                trailing: Button("保存") {
                    save()
                    self.showingModal = false
                    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                }
            )
        }
        .onAppear() {
            style = settings.themeName
            fontSize = settings.fontSize
            fontName = settings.fontName
            
            // 打印主题列表用于调试
            print("Available themes: \(themes.map { $0.name }.joined(separator: ", "))")
        }
    }
    
    // 主题滚动视图组件
    struct ThemeScrollView: View {
        let themes: [ThemeColor]
        @Binding var selectedTheme: String
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 10) {
                    ForEach(themes, id: \.self) { theme in
                        ThemeItemView(
                            theme: theme,
                            isSelected: selectedTheme == theme.name,
                            onSelect: {
                                selectedTheme = theme.name
                                // 实时预览
                                if let viewController = UIApplication.shared.windows.first?.rootViewController as? ViewController {
                                    let terminalTheme = TerminalView.TerminalThemeColor(
                                        ansiColors: theme.ansi,
                                        foreground: theme.foreground, 
                                        background: theme.background,
                                        cursor: theme.cursor,
                                        selectionColor: theme.selectionColor,
                                        isLight: Double(theme.background.brightness) > 0.5
                                    )
                                    viewController.tv.applyTheme(theme: terminalTheme)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 5)
            }
            .frame(height: 120)
        }
    }
    
    // 单个主题项视图
    struct ThemeItemView: View {
        let theme: ThemeColor
        let isSelected: Bool
        let onSelect: () -> Void
        
        var body: some View {
            VStack {
                ThemePreview(themeColor: theme, selected: isSelected)
                    .frame(width: 150, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture(perform: onSelect)
                
                Text(theme.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(5)
        }
    }
}

// iOS 特定的修复
extension View {
    // 为了兼容iOS 13，添加customOnChange实现
    func customOnChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            return self.onChange(of: value, perform: action)
        } else {
            return self.onReceive(Just(value)) { newValue in
                action(newValue)
            }
        }
    }
}
#endif 
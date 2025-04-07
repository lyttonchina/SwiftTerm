//
//  ConfigurableTerminalMacOs.swift
//  SwiftTermApp
//
//  Created by 李政 on 2025/3/2.
//  Copyright © 2025 sunrise. All rights reserved.
//

#if os(macOS)
import SwiftUI
import SwiftTerm

struct RunningTerminalConfig: View {
    @Binding var showingModal: Bool
    var terminal: LocalProcessTerminalView
    @State var style: String = settings.themeName
    @State var background: String = settings.backgroundStyle
    @State var fontName: String = settings.fontName
    @State var fontSize: CGFloat = settings.fontSize

    func save() {
        settings.themeName = style
        settings.backgroundStyle = background
        settings.fontName = fontName
        settings.fontSize = fontSize
        
        // 获取当前的 ViewController 实例并应用设置
        if let viewController = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            // 应用主题
            viewController.applyTheme(themeName: style)
            
            // 更新字体和字体大小（即使它们可能已经在预览中更新）
            viewController.changeFont(fontName, size: fontSize)
        }
    }

    var body: some View {
        VStack {
            Form {
                // 主题选择
                VStack(alignment: .leading) {
                    Text("主题选择")
                        .font(.headline)
                    
                    Text("在下方区域滑动或使用滚动条查看更多主题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        LazyHStack(spacing: 10) {
                            // 使用ForEach直接迭代所有主题
                            ForEach(themes, id: \.self) { theme in
                                VStack {
                                    ThemePreview(themeColor: theme, selected: style == theme.name)
                                        .frame(width: 150, height: 80)
                                        .border(style == theme.name ? Color.blue : Color.clear, width: 2)
                                        .onTapGesture {
                                            style = theme.name
                                            // 实时预览
                                            if let viewController = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
                                                viewController.applyTheme(themeName: theme.name)
                                            }
                                        }
                                    
                                    Text(theme.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .padding(5)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .frame(height: 120)
                    .border(Color.gray.opacity(0.5))
                }
                
                Divider()
                
                // 背景样式
                BackgroundSelector(backgroundStyle: $background, showDefault: true)
                
                // 字体
                FontSelector(fontName: $fontName)
                    .onChange(of: fontName) { newFont in
                        // 实时预览字体变化
                        terminal.changeFontSmoothly(fontName: newFont, size: fontSize)
                    }
                
                // 字体大小
                FontSizeSelector(fontName: fontName, fontSize: $fontSize)
                    .onChange(of: fontSize) { newSize in
                        // 实时预览字体大小变化
                        terminal.changeFontSizeSmoothly(newSize)
                    }
            }
            .padding(20)

            HStack {
                Button("Cancel") {
                    self.showingModal = false
                }
                Spacer()
                Button("Save") {
                    save()
                    self.showingModal = false
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 800, height: 450)
        .onAppear() {
            style = settings.themeName
            background = settings.backgroundStyle
            fontSize = settings.fontSize
            fontName = settings.fontName
            
            // 打印主题列表用于调试
            print("Available themes: \(themes.map { $0.name }.joined(separator: ", "))")
        }
    }
}
#endif


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
            
            // 更新字体大小
            viewController.changeFontSizeSmoothly(fontSize)
        }
    }

    var body: some View {
        VStack {
            Form {
                Group {
                    Text("主题选择")
                        .font(.headline)
                        .padding(.bottom, 4)
                        
                    // 确保ThemeSelector能显示所有主题
                    ScrollView(.horizontal, showsIndicators: false) {
                        ThemeSelector(themeName: $style, showDefault: false) { t in
                            style = t
                            // 实时预览主题（可选）
                            if let viewController = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
                                viewController.applyTheme(themeName: t)
                            }
                        }
                    }
                    .frame(height: 90) // 设置足够高度显示主题预览
                }
                .padding(.bottom, 10)
                
                BackgroundSelector(backgroundStyle: $background, showDefault: true)
                FontSelector(fontName: $fontName)
                FontSizeSelector(fontName: fontName, fontSize: $fontSize)
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
        .frame(width: 800, height: 400)
        .onAppear() {
            style = settings.themeName
            background = settings.backgroundStyle
            fontSize = settings.fontSize
            fontName = settings.fontName
            
            // 确保能够看到所有主题选项
            print("可用主题: \(themes.map { $0.name }.joined(separator: ", "))")
        }
    }
}
#endif


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
            if style == "Dark" {
                viewController.switchToDarkTheme()
            } else {
                viewController.switchToLightTheme()
            }
            
            // 更新字体大小
            viewController.changeFontSizeSmoothly(fontSize)
        }
    }

    var body: some View {
        VStack {
            Form {
                ScrollView(.horizontal) {
                    ThemeSelector(themeName: $style, showDefault: true) { t in
                        style = t
                    }
                    .frame(maxWidth: .infinity)
                }
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
        }
    }
}
#endif


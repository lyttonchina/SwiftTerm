//
//  SettingsViewiOS.swift
//  iOSTerminal
//
//  Created for SwiftTerm iOS.
//

import SwiftUI
import SwiftTerm
import Combine
import UIKit

// 字体大小的 UserDefaults 键
let fontSizeKey = "fontSize"

// 用于存储用户默认设置的对象
let defaults = UserDefaults.standard

// 应用设置
class Settings: ObservableObject {
    @Published var themeName: String = "Dark" {
        didSet {
            defaults.set(themeName, forKey: "theme")
            // 应用新主题到所有终端窗口
            updateAllTerminalsTheme()
        }
    }
    
    @Published var fontName: String = fontNames[0] {
        didSet {
            defaults.set(fontName, forKey: "fontName")
        }
    }
    
    @Published var fontSize: CGFloat = 0 {
        didSet {
            defaults.set(Float(fontSize), forKey: fontSizeKey)
        }
    }
    
    func resolveFontSize(_ size: CGFloat) -> CGFloat {
        if size == 0 {
            // 使用系统默认字体大小
            return UIFont.systemFontSize
        } else {
            return size
        }
    }
    
    func getTheme(themeName: String? = nil) -> ThemeColor {
        if let t = themes.first(where: { $0.name == themeName ?? self.themeName }) {
            return t
        }
        return themes[0]
    }
    
    init() {
        themeName = defaults.string(forKey: "theme") ?? "Dark"
        fontName = defaults.string(forKey: "fontName") ?? "Menlo"
        if let fontSizeConfig = defaults.object(forKey: fontSizeKey) as? Float {
            fontSize = CGFloat(fontSizeConfig) == 0 ? 0 : max(5.0, CGFloat(fontSizeConfig))
        } else {
            fontSize = 0
        }
    }
    
    // 判断一个颜色是否为亮色
    func isLightColor(_ color: SwiftTerm.Color) -> Bool {
        let r = Double(color.red) / 65535.0
        let g = Double(color.green) / 65535.0
        let b = Double(color.blue) / 65535.0
        let brightness = r * 0.299 + g * 0.587 + b * 0.114
        return brightness > 0.5
    }
    
    // 更新所有终端窗口的主题
    func updateAllTerminalsTheme() {
        // 通过通知中心发送主题更改通知
        NotificationCenter.default.post(
            name: Notification.Name("ThemeChanged"),
            object: nil,
            userInfo: ["themeName": themeName]
        )
        
        // 尝试获取主窗口的ViewController并应用主题
        if let window = UIApplication.shared.windows.first,
           let viewController = window.rootViewController as? ViewController {
            viewController.applyTheme(themeName: themeName)
        }
    }
}

var settings = Settings()
var fontNames: [String] = ["Menlo", "Courier", "Courier New", "Monaco"]

// 默认主题（基本黑白）
let defaultTheme = ThemeColor(
    name: "Default",
    ansi: [
        Color(red: 0, green: 0, blue: 0),         // Black
        Color(red: 65535, green: 0, blue: 0),     // Red
        Color(red: 0, green: 65535, blue: 0),     // Green
        Color(red: 65535, green: 65535, blue: 0), // Yellow
        Color(red: 0, green: 0, blue: 65535),     // Blue
        Color(red: 65535, green: 0, blue: 65535), // Magenta
        Color(red: 0, green: 65535, blue: 65535), // Cyan
        Color(red: 50000, green: 50000, blue: 50000), // White
        Color(red: 25000, green: 25000, blue: 25000), // Bright Black
        Color(red: 65535, green: 25000, blue: 25000), // Bright Red
        Color(red: 25000, green: 65535, blue: 25000), // Bright Green
        Color(red: 65535, green: 65535, blue: 25000), // Bright Yellow
        Color(red: 25000, green: 25000, blue: 65535), // Bright Blue
        Color(red: 65535, green: 25000, blue: 65535), // Bright Magenta
        Color(red: 25000, green: 65535, blue: 65535), // Bright Cyan
        Color(red: 65535, green: 65535, blue: 65535)  // Bright White
    ],
    background: Color(red: 0, green: 0, blue: 0),
    foreground: Color(red: 65535, green: 65535, blue: 65535),
    cursor: Color(red: 65535, green: 65535, blue: 65535),
    cursorText: Color(red: 0, green: 0, blue: 0),
    selectedText: Color(red: 0, green: 0, blue: 0),
    selectionColor: Color(red: 25000, green: 25000, blue: 65535)
)

// 主题列表
var themes: [ThemeColor] = [
    defaultTheme,
    // 添加更多预设主题...
]

// 主题预览组件
struct ThemePreview: View {
    var themeColor: ThemeColor
    var title: String?
    var selected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 模拟终端外观
            ZStack {
                Rectangle()
                    .fill(Color(red: Double(themeColor.background.red) / 65535.0,
                                green: Double(themeColor.background.green) / 65535.0,
                                blue: Double(themeColor.background.blue) / 65535.0))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("$ ls -la")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(red: Double(themeColor.foreground.red) / 65535.0,
                                              green: Double(themeColor.foreground.green) / 65535.0,
                                              blue: Double(themeColor.foreground.blue) / 65535.0))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<8) { i in
                            Rectangle()
                                .fill(Color(red: Double(themeColor.ansi[i].red) / 65535.0,
                                            green: Double(themeColor.ansi[i].green) / 65535.0,
                                            blue: Double(themeColor.ansi[i].blue) / 65535.0))
                                .frame(width: 10, height: 8)
                        }
                    }
                    
                    HStack(spacing: 2) {
                        ForEach(8..<16) { i in
                            Rectangle()
                                .fill(Color(red: Double(themeColor.ansi[i].red) / 65535.0,
                                            green: Double(themeColor.ansi[i].green) / 65535.0,
                                            blue: Double(themeColor.ansi[i].blue) / 65535.0))
                                .frame(width: 10, height: 8)
                        }
                    }
                }
                .padding(4)
            }
            
            // 主题名称
            if let title = title {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            } else {
                Text(themeColor.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// 主题选择器组件
struct ThemeSelector: View {
    @Binding var themeName: String
    @State var showDefault = false
    var callback: (_ themeName: String) -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("主题")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 10) {
                    if showDefault {
                        ThemePreview(themeColor: settings.getTheme(), title: "默认", selected: themeName.isEmpty)
                            .frame(width: 120, height: 90)
                            .onTapGesture {
                                self.themeName = ""
                                self.callback("")
                                settings.updateAllTerminalsTheme()
                            }
                    }
                    
                    ForEach(themes, id: \.self) { theme in
                        ThemePreview(themeColor: theme, selected: themeName == theme.name)
                            .frame(width: 120, height: 90)
                            .onTapGesture {
                                self.themeName = theme.name
                                self.callback(theme.name)
                                settings.updateAllTerminalsTheme()
                            }
                    }
                }
                .padding(.vertical, 5)
            }
            .frame(height: 120)
        }
    }
}

// 字体选择器组件
struct FontSelector: View {
    @Binding var fontName: String
    private let fontNames = [
        "Menlo", "Courier", "Courier New", "Monaco"
    ]
    
    func mapName(_ fontName: String) -> String {
        return fontName
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("字体")
                .font(.headline)
            
            Picker(selection: $fontName, label: Text("")) {
                ForEach(fontNames, id: \.self) { name in
                    Text(mapName(name))
                        .font(.custom(name, size: 17))
                        .tag(name)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 120)
        }
    }
}

// 字体大小选择器组件
struct FontSizeSelector: View {
    var fontName: String
    @Binding var fontSize: CGFloat
    private let fontSizes: [CGFloat] = [8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("字体大小")
                .font(.headline)
            
            HStack {
                Text("A")
                    .font(.system(size: 12))
                
                Slider(value: Binding(
                    get: {
                        // 将fontSize转换为滑块的0-1值
                        let sizes = fontSizes
                        guard let index = sizes.firstIndex(where: { $0 >= fontSize }) else {
                            return 1.0
                        }
                        return Double(index) / Double(sizes.count - 1)
                    },
                    set: {
                        // 将滑块的0-1值转换为fontSize
                        let sizes = fontSizes
                        let index = Int(round($0 * Double(sizes.count - 1)))
                        fontSize = sizes[index]
                    }
                ))
                
                Text("A")
                    .font(.system(size: 24))
            }
            
            Text("\(Int(fontSize))pt")
                .font(.custom(fontName, size: fontSize))
                .padding(.top, 8)
        }
    }
}

// iOS终端设置视图
struct TerminalSettingsView: View {
    @Binding var isPresented: Bool
    var terminal: SshTerminalView
    
    @State private var themeName: String = settings.themeName
    @State private var fontName: String = settings.fontName
    @State private var fontSize: CGFloat = settings.fontSize
    
    func saveSettings() {
        settings.themeName = themeName
        settings.fontName = fontName
        settings.fontSize = fontSize
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // 主题选择
                    ThemeSelector(themeName: $themeName, showDefault: true) { newTheme in
                        // 实时预览主题
                        if let viewController = UIApplication.shared.windows.first?.rootViewController as? ViewController {
                            viewController.applyTheme(themeName: newTheme)
                        }
                    }
                }
                
                Section {
                    // 字体选择
                    FontSelector(fontName: $fontName)
                        // 移除实时预览
                        //.onReceive(Just(fontName)) { newFont in
                        //    // 实时预览字体
                        //    terminal.changeFontSmoothly(fontName: newFont, size: fontSize)
                        //}
                }
                
                Section {
                    // 字体大小选择
                    FontSizeSelector(fontName: fontName, fontSize: $fontSize)
                        // 移除实时预览
                        //.onReceive(Just(fontSize)) { newSize in
                        //    // 实时预览字体大小
                        //    terminal.changeFontSizeSmoothly(newSize)
                        //}
                }
                
                // 添加提示信息
                Section {
                    Text("字体更改将在保存后应用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitle("终端设置", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    saveSettings()
                    isPresented = false
                }
            )
        }
    }
}

// 预览
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // 由于依赖于TerminalView，实际预览中这部分会有错误，需要在实际设备中测试
        Text("Settings Preview Placeholder")
    }
} 
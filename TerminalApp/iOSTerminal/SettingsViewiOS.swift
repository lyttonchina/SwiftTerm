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
    }
}

var settings = Settings()
var fontNames: [String] = ["Menlo", "Courier", "Courier New", "Monaco"]

// 默认主题（基本黑白）
let defaultTheme = ThemeColor(
    name: "System Default",
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

// 从macOS版本复制的主题字符串
let themeBuiltinDark = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #bb0000
#define Ansi_10_Color #55ff55
#define Ansi_11_Color #ffff55
#define Ansi_12_Color #5555ff
#define Ansi_13_Color #ff55ff
#define Ansi_14_Color #55ffff
#define Ansi_15_Color #ffffff
#define Ansi_2_Color #00bb00
#define Ansi_3_Color #bbbb00
#define Ansi_4_Color #0000bb
#define Ansi_5_Color #bb00bb
#define Ansi_6_Color #00bbbb
#define Ansi_7_Color #bbbbbb
#define Ansi_8_Color #555555
#define Ansi_9_Color #ff5555
#define Background_Color #000000
#define Badge_Color #ff0000
#define Bold_Color #ffffff
#define Cursor_Color #bbbbbb
#define Cursor_Guide_Color #a6e8ff
#define Cursor_Text_Color #ffffff
#define Foreground_Color #bbbbbb
#define Link_Color #0645ad
#define Selected_Text_Color #000000
#define Selection_Color #b5d5ff
"""

let themeBuiltinLight = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #bb0000
#define Ansi_10_Color #55ff55
#define Ansi_11_Color #ffff55
#define Ansi_12_Color #5555ff
#define Ansi_13_Color #ff55ff
#define Ansi_14_Color #55ffff
#define Ansi_15_Color #ffffff
#define Ansi_2_Color #00bb00
#define Ansi_3_Color #bbbb00
#define Ansi_4_Color #0000bb
#define Ansi_5_Color #bb00bb
#define Ansi_6_Color #00bbbb
#define Ansi_7_Color #bbbbbb
#define Ansi_8_Color #555555
#define Ansi_9_Color #ff5555
#define Background_Color #ffffff
#define Badge_Color #ff0000
#define Bold_Color #000000
#define Cursor_Color #000000
#define Cursor_Guide_Color #a6e8ff
#define Cursor_Text_Color #ffffff
#define Foreground_Color #000000
#define Link_Color #0645ad
#define Selected_Text_Color #000000
#define Selection_Color #b5d5ff
"""

let themeSolarizedDark = """
#define Ansi_0_Color #073642
#define Ansi_1_Color #dc322f
#define Ansi_10_Color #586e75
#define Ansi_11_Color #657b83
#define Ansi_12_Color #839496
#define Ansi_13_Color #6c71c4
#define Ansi_14_Color #93a1a1
#define Ansi_15_Color #fdf6e3
#define Ansi_2_Color #859900
#define Ansi_3_Color #b58900
#define Ansi_4_Color #268bd2
#define Ansi_5_Color #d33682
#define Ansi_6_Color #2aa198
#define Ansi_7_Color #eee8d5
#define Ansi_8_Color #002b36
#define Ansi_9_Color #cb4b16
#define Background_Color #002b36
#define Badge_Color #ff2600
#define Bold_Color #93a1a1
#define Cursor_Color #839496
#define Cursor_Guide_Color #b3ecff
#define Cursor_Text_Color #073642
#define Foreground_Color #839496
#define Link_Color #005cbb
#define Selected_Text_Color #93a1a1
#define Selection_Color #073642
"""

let themeSolarizedLight = """
#define Ansi_0_Color #073642
#define Ansi_1_Color #dc322f
#define Ansi_10_Color #586e75
#define Ansi_11_Color #657b83
#define Ansi_12_Color #839496
#define Ansi_13_Color #6c71c4
#define Ansi_14_Color #93a1a1
#define Ansi_15_Color #fdf6e3
#define Ansi_2_Color #859900
#define Ansi_3_Color #b58900
#define Ansi_4_Color #268bd2
#define Ansi_5_Color #d33682
#define Ansi_6_Color #2aa198
#define Ansi_7_Color #eee8d5
#define Ansi_8_Color #002b36
#define Ansi_9_Color #cb4b16
#define Background_Color #ffffff
#define Badge_Color #ff2600
#define Bold_Color #586e75
#define Cursor_Color #657b83
#define Cursor_Guide_Color #b3ecff
#define Cursor_Text_Color #eee8d5
#define Foreground_Color #657b83
#define Link_Color #005cbb
#define Selected_Text_Color #586e75
#define Selection_Color #eee8d5
"""

let themeMaterial = """
#define Ansi_0_Color #212121
#define Ansi_1_Color #b7141f
#define Ansi_10_Color #7aba3a
#define Ansi_11_Color #ffea2e
#define Ansi_12_Color #54a4f3
#define Ansi_13_Color #aa4dbc
#define Ansi_14_Color #26bbd1
#define Ansi_15_Color #d9d9d9
#define Ansi_2_Color #457b24
#define Ansi_3_Color #f6981e
#define Ansi_4_Color #134eb2
#define Ansi_5_Color #560088
#define Ansi_6_Color #0e717c
#define Ansi_7_Color #efefef
#define Ansi_8_Color #424242
#define Ansi_9_Color #e83b3f
#define Background_Color #eaeaea
#define Bold_Color #b7141f
#define Cursor_Color #16afca
#define Cursor_Text_Color #2e2e2d
#define Foreground_Color #232322
#define Selected_Text_Color #4e4e4e
#define Selection_Color #c2c2c2
"""

let themeOcean = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #990000
#define Ansi_10_Color #00d900
#define Ansi_11_Color #e5e500
#define Ansi_12_Color #0000ff
#define Ansi_13_Color #e500e5
#define Ansi_14_Color #00e5e5
#define Ansi_15_Color #e5e5e5
#define Ansi_2_Color #00a600
#define Ansi_3_Color #999900
#define Ansi_4_Color #0000b2
#define Ansi_5_Color #b200b2
#define Ansi_6_Color #00a6b2
#define Ansi_7_Color #bfbfbf
#define Ansi_8_Color #666666
#define Ansi_9_Color #e50000
#define Background_Color #224fbc
#define Bold_Color #ffffff
#define Cursor_Color #7f7f7f
#define Cursor_Text_Color #ffffff
#define Foreground_Color #ffffff
#define Selected_Text_Color #ffffff
#define Selection_Color #216dff
"""

let themeAdventureTime = """
#define Ansi_0_Color #050404
#define Ansi_1_Color #bd0013
#define Ansi_10_Color #9eff6e
#define Ansi_11_Color #efc11a
#define Ansi_12_Color #1997c6
#define Ansi_13_Color #9b5953
#define Ansi_14_Color #c8faf4
#define Ansi_15_Color #f6f5fb
#define Ansi_2_Color #4ab118
#define Ansi_3_Color #e7741e
#define Ansi_4_Color #0f4ac6
#define Ansi_5_Color #665993
#define Ansi_6_Color #70a598
#define Ansi_7_Color #f8dcc0
#define Ansi_8_Color #4e7cbf
#define Ansi_9_Color #fc5f5a
#define Background_Color #1f1d45
#define Bold_Color #bd0013
#define Cursor_Color #efbf38
#define Cursor_Text_Color #08080a
#define Foreground_Color #f8dcc0
#define Selected_Text_Color #f3d9c4
#define Selection_Color #706b4e
"""

let themePro = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #990000
#define Ansi_10_Color #00d900
#define Ansi_11_Color #e5e500
#define Ansi_12_Color #0000ff
#define Ansi_13_Color #e500e5
#define Ansi_14_Color #00e5e5
#define Ansi_15_Color #e5e5e5
#define Ansi_2_Color #00a600
#define Ansi_3_Color #999900
#define Ansi_4_Color #2009db
#define Ansi_5_Color #b200b2
#define Ansi_6_Color #00a6b2
#define Ansi_7_Color #bfbfbf
#define Ansi_8_Color #666666
#define Ansi_9_Color #e50000
#define Background_Color #000000
#define Bold_Color #ffffff
#define Cursor_Color #4d4d4d
#define Cursor_Text_Color #ffffff
#define Foreground_Color #f2f2f2
#define Selected_Text_Color #000000
#define Selection_Color #414141
"""

let themeDjango = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #fd6209
#define Ansi_10_Color #73da70
#define Ansi_11_Color #ffff94
#define Ansi_12_Color #568264
#define Ansi_13_Color #ffffff
#define Ansi_14_Color #cfffd1
#define Ansi_15_Color #ffffff
#define Ansi_2_Color #41a83e
#define Ansi_3_Color #ffe862
#define Ansi_4_Color #245032
#define Ansi_5_Color #f8f8f8
#define Ansi_6_Color #9df39f
#define Ansi_7_Color #ffffff
#define Ansi_8_Color #323232
#define Ansi_9_Color #ff943b
#define Background_Color #0b2f20
#define Bold_Color #f8f8f8
#define Cursor_Color #336442
#define Cursor_Text_Color #f8f8f8
#define Foreground_Color #f8f8f8
#define Selected_Text_Color #f8f8f8
#define Selection_Color #245032
"""

let themeTangoDark = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #cc0000
#define Ansi_10_Color #8ae234
#define Ansi_11_Color #fce94f
#define Ansi_12_Color #729fcf
#define Ansi_13_Color #ad7fa8
#define Ansi_14_Color #34e2e2
#define Ansi_15_Color #eeeeec
#define Ansi_2_Color #4e9a06
#define Ansi_3_Color #c4a000
#define Ansi_4_Color #3465a4
#define Ansi_5_Color #75507b
#define Ansi_6_Color #06989a
#define Ansi_7_Color #d3d7cf
#define Ansi_8_Color #555753
#define Ansi_9_Color #ef2929
#define Background_Color #000000
#define Badge_Color #ff0000
#define Bold_Color #ffffff
#define Cursor_Color #ffffff
#define Cursor_Guide_Color #a6e8ff
#define Cursor_Text_Color #000000
#define Foreground_Color #ffffff
#define Link_Color #0645ad
#define Selected_Text_Color #000000
#define Selection_Color #b5d5ff
"""

let themeTangoLight = """
#define Ansi_0_Color #000000
#define Ansi_1_Color #cc0000
#define Ansi_10_Color #8ae234
#define Ansi_11_Color #fce94f
#define Ansi_12_Color #729fcf
#define Ansi_13_Color #ad7fa8
#define Ansi_14_Color #34e2e2
#define Ansi_15_Color #eeeeec
#define Ansi_2_Color #4e9a06
#define Ansi_3_Color #c4a000
#define Ansi_4_Color #3465a4
#define Ansi_5_Color #75507b
#define Ansi_6_Color #06989a
#define Ansi_7_Color #d3d7cf
#define Ansi_8_Color #555753
#define Ansi_9_Color #ef2929
#define Background_Color #ffffff
#define Badge_Color #ff0000
#define Bold_Color #000000
#define Cursor_Color #000000
#define Cursor_Guide_Color #a6e8ff
#define Cursor_Text_Color #ffffff
#define Foreground_Color #000000
#define Link_Color #0645ad
#define Selected_Text_Color #000000
#define Selection_Color #b5d5ff
"""

// 主题列表
var themes: [ThemeColor] = [
    defaultTheme,
    ThemeColor.fromXrdb(title: "Dark", xrdb: themeBuiltinDark)!,
    ThemeColor.fromXrdb(title: "Light", xrdb: themeBuiltinLight)!,
    ThemeColor.fromXrdb(title: "Solarized Dark", xrdb: themeSolarizedDark)!,
    ThemeColor.fromXrdb(title: "Solarized Light", xrdb: themeSolarizedLight)!,
    ThemeColor.fromXrdb(title: "Material", xrdb: themeMaterial)!,
    ThemeColor.fromXrdb(title: "Ocean", xrdb: themeOcean)!,
    ThemeColor.fromXrdb(title: "Adventure Time", xrdb: themeAdventureTime)!,
    ThemeColor.fromXrdb(title: "Pro", xrdb: themePro)!,
    ThemeColor.fromXrdb(title: "Django", xrdb: themeDjango)!,
    ThemeColor.fromXrdb(title: "Tango Dark", xrdb: themeTangoDark)!,
    ThemeColor.fromXrdb(title: "Tango Light", xrdb: themeTangoLight)!,
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
                                print("选择主题: \(theme.name)")
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
                    ThemeSelector(themeName: $themeName) { newTheme in
                        // 设置主题
                        settings.themeName = newTheme
                    }
                }
                
                Section {
                    // 字体选择
                    FontSelector(fontName: $fontName)
                }
                
                Section {
                    // 字体大小选择
                    FontSizeSelector(fontName: fontName, fontSize: $fontSize)
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
                    
                    // 应用字体设置
                    if let viewController = UIApplication.shared.windows.first?.rootViewController as? ViewController {
                        viewController.tv.changeFontSmoothly(fontName: settings.fontName, size: settings.fontSize)
                    }
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
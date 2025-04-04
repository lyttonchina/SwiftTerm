//
//  SettingsView_macOS.swift
//  SwiftTermApp
//
//  Created by Miguel de Icaza on 2023/2/15.
//

#if os(macOS)
import SwiftUI
import Foundation
import AppKit
import SwiftTerm

// 字体大小的 UserDefaults 键
let fontSizeKey = "fontSize"

// 用于存储用户默认设置的对象
let defaults = UserDefaults.standard

// 定义可用的主题列表
let themes: [ThemeColor] = {
    var result: [ThemeColor] = []
    
    // 安全添加主题，如果解析失败则跳过
    func safeAddTheme(title: String, xrdb: String) {
        if let theme = ThemeColor.fromXrdb(title: title, xrdb: xrdb) {
            result.append(theme)
        } else {
            print("警告: 无法解析主题 \(title)")
        }
    }
    
    safeAddTheme(title: "Adventure Time", xrdb: themeAdventureTime)
    safeAddTheme(title: "Dark", xrdb: themeBuiltinDark)
    safeAddTheme(title: "Django", xrdb: themeDjango)
    safeAddTheme(title: "Light", xrdb: themeBuiltinLight)
    safeAddTheme(title: "Material", xrdb: themeMaterial)
    safeAddTheme(title: "Ocean", xrdb: themeOcean)
    safeAddTheme(title: "Pro", xrdb: themePro)
    safeAddTheme(title: "Solarized Dark", xrdb: themeSolarizedDark)
    safeAddTheme(title: "Solarized Light", xrdb: themeSolarizedLight)
    safeAddTheme(title: "Tango Dark", xrdb: themeTangoDark)
    safeAddTheme(title: "Tango Light", xrdb: themeTangoLight)
    
    // 确保至少有一个有效的主题
    if result.isEmpty {
        // 创建一个默认的暗色主题
        let ansiColors = [
            SwiftTerm.Color(red: 0, green: 0, blue: 0),                // 黑色
            SwiftTerm.Color(red: 0xBB00, green: 0, blue: 0),           // 红色
            SwiftTerm.Color(red: 0, green: 0xBB00, blue: 0),           // 绿色
            SwiftTerm.Color(red: 0xBB00, green: 0xBB00, blue: 0),      // 黄色
            SwiftTerm.Color(red: 0, green: 0, blue: 0xBB00),           // 蓝色
            SwiftTerm.Color(red: 0xBB00, green: 0, blue: 0xBB00),      // 洋红
            SwiftTerm.Color(red: 0, green: 0xBB00, blue: 0xBB00),      // 青色
            SwiftTerm.Color(red: 0xBBBB, green: 0xBBBB, blue: 0xBBBB), // 白色
            SwiftTerm.Color(red: 0x5555, green: 0x5555, blue: 0x5555), // 亮黑
            SwiftTerm.Color(red: 0xFF55, green: 0x5555, blue: 0x5555), // 亮红
            SwiftTerm.Color(red: 0x55FF, green: 0xFF55, blue: 0x5555), // 亮绿
            SwiftTerm.Color(red: 0xFFFF, green: 0xFF55, blue: 0x5555), // 亮黄
            SwiftTerm.Color(red: 0x5555, green: 0x5555, blue: 0xFF55), // 亮蓝
            SwiftTerm.Color(red: 0xFF55, green: 0x5555, blue: 0xFF55), // 亮洋红
            SwiftTerm.Color(red: 0x5555, green: 0xFF55, blue: 0xFF55), // 亮青
            SwiftTerm.Color(red: 0xFFFF, green: 0xFFFF, blue: 0xFFFF)  // 亮白
        ]
        
        // 手动构建一个基本的暗色主题
        let defaultDark = ThemeColor(
            name: "DefaultDark", 
            ansi: ansiColors, 
            background: SwiftTerm.Color(red: 0, green: 0, blue: 0), 
            foreground: SwiftTerm.Color(red: 0xBBBB, green: 0xBBBB, blue: 0xBBBB), 
            cursor: SwiftTerm.Color(red: 0xBBBB, green: 0xBBBB, blue: 0xBBBB), 
            cursorText: SwiftTerm.Color(red: 0, green: 0, blue: 0), 
            selectedText: SwiftTerm.Color(red: 0, green: 0, blue: 0), 
            selectionColor: SwiftTerm.Color(red: 0x3333, green: 0x6666, blue: 0xCCCC)
        )
        result.append(defaultDark)
    }
    
    return result
}()

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
            defaults.set(fontSize, forKey: fontSizeKey)
        }
    }
    
    @Published var backgroundStyle: String = "" {
        didSet {
            defaults.set(backgroundStyle, forKey: "backgroundStyle")
        }
    }
    
    func resolveFontSize(_ size: CGFloat) -> CGFloat {
        if size == 0 {
            // 兼容低版本macOS
            return NSFont.systemFontSize
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
        if let fontSizeConfig = defaults.object(forKey: fontSizeKey) as? CGFloat {
            fontSize = fontSizeConfig == 0 ? 0 : max(5.0, fontSizeConfig)
        } else {
            fontSize = 0
        }
        backgroundStyle = defaults.string(forKey: "backgroundStyle") ?? "Solid"
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
        if let mainWindow = NSApplication.shared.mainWindow,
           let viewController = mainWindow.contentViewController as? ViewController {
            viewController.applyTheme(themeName: themeName)
        }
        
        // 获取所有窗口并尝试应用主题
        for window in NSApplication.shared.windows {
            if let viewController = window.contentViewController as? ViewController {
                viewController.applyTheme(themeName: themeName)
            }
        }
    }
}

var settings = Settings()
var fontNames: [String] = ["Courier", "Courier New", "Menlo", "SF Mono"]

func term2ui(_ stcolor: SwiftTerm.Color) -> SwiftUI.Color {
    SwiftUI.Color(red: Double(stcolor.red) / 65535.0,
                  green: Double(stcolor.green) / 65535.0,
                  blue: Double(stcolor.blue) / 65535.0)
}

struct ColorSwatch: View {
    var color: SwiftTerm.Color
    var body: some View {
        Rectangle()
            .fill(term2ui(color))
            .frame(width: 11, height: 11)
            .shadow(radius: 1)
    }
}

struct ThemePreview: View {
    var themeColor: ThemeColor
    var title: String? = nil
    var selected: Bool = false
    var body: some View {
        ZStack {
            Rectangle()
                .fill(term2ui(themeColor.background))
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title ?? themeColor.name)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .padding([.leading, .top], 4)
                        .foregroundColor(term2ui(themeColor.foreground))
                    Spacer()
                }.frame(height: 24)
                HStack(spacing: 5) {
                    ForEach(0..<7) { x in
                        ColorSwatch(color: self.themeColor.ansi[x])
                    }
                }
                HStack(spacing: 5) {
                    ForEach(8..<15) { x in
                        ColorSwatch(color: self.themeColor.ansi[x])
                    }
                }
            }
        }
        .frame(width: 120, height: 70)
        .border(selected ? Color.black : Color.clear)
    }
}

struct FontSize: View {
    var fontName: String
    var size: CGFloat
    @Binding var currentSize: CGFloat
    var caption: String?
    var body: some View {
        Text(self.caption ?? "\(Int(self.size))")
            .padding(5)
            .background(size == currentSize ? Color.blue : Color.gray)
            .foregroundColor(Color.white)
            .cornerRadius(5)
            .onTapGesture {
                self.currentSize = self.size
                // 实时预览字体大小
                if let viewController = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
                    viewController.changeFontSizeSmoothly(self.size == 0 ? NSFont.systemFontSize : self.size)
                }
            }
    }
}

struct ThemeSelector: View {
    @Binding var themeName: String
    @State var showDefault = false
    var callback: (_ themeName: String) -> ()
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if showDefault {
                    ThemePreview(themeColor: settings.getTheme(), title: "Default")
                        .padding(1)
                        .border(self.themeName == "" ? Color.accentColor : Color.clear, width: 2)
                        .onTapGesture {
                            self.themeName = ""
                            self.callback("")
                            settings.updateAllTerminalsTheme()
                        }
                }
                ForEach(themes, id: \.self) { t in
                    ThemePreview(themeColor: t)
                        .padding(1)
                        .border(self.themeName == t.name ? Color.accentColor : Color.clear, width: 2)
                        .onTapGesture {
                            self.themeName = t.name
                            self.callback(t.name)
                            settings.updateAllTerminalsTheme()
                        }
                }
            }
        }
    }
}

struct FontSelector: View {
    @Binding var fontName: String
    
    func mapName(_ fontName: String) -> String {
        if fontName == "SourceCodePro-Medium" {
            return "Source Code Pro"
        }
        return fontName
    }
    
    var body: some View {
        Picker(selection: $fontName, label: Text("Font")) {
            ForEach(fontNames, id: \.self) { fontName in
                Text(mapName(fontName))
                    .font(.custom(fontName, size: 17))
                    .tag(fontName)
            }
        }
    }
}

struct FontSizeSelector: View {
    var fontName: String
    @Binding var fontSize: CGFloat
    var fontSizes: [CGFloat] = [8, 10, 11, 12, 14, 18, 24]
    var body: some View {
        HStack {
            Text("Size")
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .center) {
                    FontSize(fontName: self.fontName, size: 0, currentSize: self.$fontSize, caption: " System ")
                        .onTapGesture {
                            self.fontSize = 0
                        }
                    ForEach(fontSizes, id: \.self) { size in
                        FontSize(fontName: self.fontName, size: size, currentSize: self.$fontSize, caption: "\(Int(size))")
                            .onTapGesture {
                                self.fontSize = size
                            }
                    }
                }
            }
        }
    }
}

struct BackgroundSelector: View {
    @Binding var backgroundStyle: String
    @State var showDefault = false
    
    var body: some View {
        Picker(selection: $backgroundStyle, label: Text("Background Style")) {
            Text("Solid").tag("Solid")
            Text("Gradient").tag("Gradient")
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct SettingsViewCore: View {
    @Binding var themeName: String
    @Binding var fontName: String
    @Binding var fontSize: CGFloat
    @Binding var backgroundStyle: String
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                VStack(alignment: .leading) {
                    Text("Color Theme")
                    ThemeSelector(themeName: $themeName) {
                        settings.themeName = $0
                    }
                }
                FontSelector(fontName: $fontName)
                FontSizeSelector(fontName: fontName, fontSize: $fontSize)
                BackgroundSelector(backgroundStyle: $backgroundStyle)
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var gset = settings
    
    var body: some View {
        SettingsViewCore(themeName: $gset.themeName,
                         fontName: $gset.fontName,
                         fontSize: $gset.fontSize,
                         backgroundStyle: $gset.backgroundStyle)
    }
}

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
#endif

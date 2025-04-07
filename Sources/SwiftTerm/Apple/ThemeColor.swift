//
//  ThemeColor.swift
//  SwiftTerm
//
//  Created by 李政 on 2025/4/7.
//

//
//  ThemeColor.swift
//  SwiftTerm
//
//  提供终端主题颜色定义和XRM格式解析
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation

/// 终端主题颜色定义，包含ANSI和UI颜色
public struct ThemeColor: Hashable, Equatable {
    /// 主题名称
    public var name: String
    
    /// ANSI颜色组（16色）
    public var ansi: [Color]
    
    /// 终端背景色
    public var background: Color
    
    /// 终端前景色
    public var foreground: Color
    
    /// 光标颜色
    public var cursor: Color
    
    /// 光标文字颜色
    public var cursorText: Color
    
    /// 选中文字颜色
    public var selectedText: Color
    
    /// 选中背景颜色
    public var selectionColor: Color
    
    /// 创建一个主题颜色定义
    public init(name: String, ansi: [Color], background: Color, foreground: Color, cursor: Color, cursorText: Color, selectedText: Color, selectionColor: Color) {
        self.name = name
        self.ansi = ansi
        self.background = background
        self.foreground = foreground
        self.cursor = cursor
        self.cursorText = cursorText
        self.selectedText = selectedText
        self.selectionColor = selectionColor
    }
    
    // Hashable协议实现
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    // Equatable协议实现
    public static func == (lhs: ThemeColor, rhs: ThemeColor) -> Bool {
        return lhs.name == rhs.name
    }
    
    /// 从hex字符串解析颜色
    public static func parseColor(_ txt: [Character]) -> Color? {
        func getHex(_ idx: Int) -> UInt16 {
            var n: UInt16 = 0
            let c = txt[idx].asciiValue ?? 0
            
            if c >= UInt8(ascii: "0") && c <= UInt8(ascii: "9") {
                n = UInt16(c - UInt8(ascii: "0"))
            } else if c >= UInt8(ascii: "a") && c <= UInt8(ascii: "f") {
                n = UInt16((c - UInt8(ascii: "a") + 10))
            } else if c >= UInt8(ascii: "A") && c <= UInt8(ascii: "F") {
                n = UInt16((c - UInt8(ascii: "A") + 10))
            }
            return n
        }
        
        guard txt.count == 7 else { return nil }
        guard txt[0] == "#" else { return nil }
        
        let r = getHex(1) << 4 | getHex(2)
        let g = getHex(3) << 4 | getHex(4)
        let b = getHex(5) << 4 | getHex(6)
        return Color(red: r*257, green: g*257, blue: b*257)
    }
    
    /// 从Xrdb格式字符串创建主题
    /// - Parameters:
    ///   - title: 主题名称
    ///   - xrdb: 包含全部Xrdb格式内容的字符串
    /// - Returns: 解析后的主题颜色，解析失败返回nil
    public static func fromXrdb(title: String, xrdb: String) -> ThemeColor? {
        var ansi: [Int:Color] = [:]
        var background: Color?
        var foreground: Color?
        var cursor: Color?
        var cursorText: Color?
        var selectedText: Color?
        var selectionColor: Color?
        
        for l in xrdb.split(separator: "\n") {
            let elements = l.split(separator: " ")
            guard elements.count >= 3 else { continue }
            
            let color = parseColor(Array(elements[2]))
            switch elements[1] {
            case "Ansi_0_Color":
                ansi[0] = color
            case "Ansi_1_Color":
                ansi[1] = color
            case "Ansi_10_Color":
                ansi[10] = color
            case "Ansi_11_Color":
                ansi[11] = color
            case "Ansi_12_Color":
                ansi[12] = color
            case "Ansi_13_Color":
                ansi[13] = color
            case "Ansi_14_Color":
                ansi[14] = color
            case "Ansi_15_Color":
                ansi[15] = color
            case "Ansi_2_Color":
                ansi[2] = color
            case "Ansi_3_Color":
                ansi[3] = color
            case "Ansi_4_Color":
                ansi[4] = color
            case "Ansi_5_Color":
                ansi[5] = color
            case "Ansi_6_Color":
                ansi[6] = color
            case "Ansi_7_Color":
                ansi[7] = color
            case "Ansi_8_Color":
                ansi[8] = color
            case "Ansi_9_Color":
                ansi[9] = color
            case "Background_Color":
                background = color
            case "Cursor_Color":
                cursor = color
            case "Cursor_Text_Color":
                cursorText = color
            case "Foreground_Color":
                foreground = color
            case "Selected_Text_Color":
                selectedText = color
            case "Selection_Color":
                selectionColor = color
            default:
                break
            }
        }
        
        if ansi.count == 16 {
            if let bg = background, let fg = foreground, let ct = cursorText,
               let cu = cursor, let st = selectedText, let sc = selectionColor {
                
                return ThemeColor(name: title,
                                  ansi: [Color](ansi.keys.sorted().map { v in ansi[v]! }),
                                  background: bg,
                                  foreground: fg,
                                  cursor: cu,
                                  cursorText: ct,
                                  selectedText: st,
                                  selectionColor: sc)
            }
        }
        return nil
    }
    
    /// 创建基本的暗色主题
    public static var defaultDark: ThemeColor {
        // 创建一个基本的暗色主题
        let black = Color(red: 0, green: 0, blue: 0)
        let white = Color(red: 65535, green: 65535, blue: 65535)
        let gray = Color(red: 30000, green: 30000, blue: 30000)
        let brightGray = Color(red: 45000, green: 45000, blue: 45000)
        
        // 基本ANSI颜色
        let red = Color(red: 65535, green: 0, blue: 0)
        let green = Color(red: 0, green: 65535, blue: 0)
        let blue = Color(red: 0, green: 0, blue: 65535)
        let yellow = Color(red: 65535, green: 65535, blue: 0)
        let magenta = Color(red: 65535, green: 0, blue: 65535)
        let cyan = Color(red: 0, green: 65535, blue: 65535)
        
        // 亮色ANSI颜色
        let brightRed = Color(red: 65535, green: 30000, blue: 30000)
        let brightGreen = Color(red: 30000, green: 65535, blue: 30000)
        let brightBlue = Color(red: 30000, green: 30000, blue: 65535)
        let brightYellow = Color(red: 65535, green: 65535, blue: 30000)
        let brightMagenta = Color(red: 65535, green: 30000, blue: 65535)
        let brightCyan = Color(red: 30000, green: 65535, blue: 65535)
        
        return ThemeColor(
            name: "Default Dark",
            ansi: [black, red, green, yellow, blue, magenta, cyan, white,
                   gray, brightRed, brightGreen, brightYellow, brightBlue, brightMagenta, brightCyan, brightGray],
            background: black,
            foreground: white,
            cursor: white,
            cursorText: black,
            selectedText: white,
            selectionColor: blue
        )
    }
    
    /// 创建基本的亮色主题
    public static var defaultLight: ThemeColor {
        // 创建一个基本的亮色主题
        let black = Color(red: 0, green: 0, blue: 0)
        let white = Color(red: 65535, green: 65535, blue: 65535)
        let lightGray = Color(red: 55000, green: 55000, blue: 55000)
        let darkGray = Color(red: 20000, green: 20000, blue: 20000)
        
        // 基本ANSI颜色 - 暗色版本适合亮色主题
        let red = Color(red: 45535, green: 0, blue: 0)
        let green = Color(red: 0, green: 45535, blue: 0)
        let blue = Color(red: 0, green: 0, blue: 45535)
        let yellow = Color(red: 45535, green: 45535, blue: 0)
        let magenta = Color(red: 45535, green: 0, blue: 45535)
        let cyan = Color(red: 0, green: 45535, blue: 45535)
        
        // 亮色ANSI颜色
        let brightRed = Color(red: 65535, green: 20000, blue: 20000)
        let brightGreen = Color(red: 20000, green: 65535, blue: 20000)
        let brightBlue = Color(red: 20000, green: 20000, blue: 65535)
        let brightYellow = Color(red: 65535, green: 65535, blue: 20000)
        let brightMagenta = Color(red: 65535, green: 20000, blue: 65535)
        let brightCyan = Color(red: 20000, green: 65535, blue: 65535)
        
        return ThemeColor(
            name: "Default Light",
            ansi: [black, red, green, yellow, blue, magenta, cyan, darkGray,
                   lightGray, brightRed, brightGreen, brightYellow, brightBlue, brightMagenta, brightCyan, white],
            background: white,
            foreground: black,
            cursor: black,
            cursorText: white,
            selectedText: white,
            selectionColor: blue
        )
    }
}
#endif

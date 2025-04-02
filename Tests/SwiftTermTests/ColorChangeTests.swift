import XCTest
@testable import SwiftTerm

final class ColorChangeTests: XCTestCase {
    // A simple terminal delegate implementation for testing
    class TestTerminalDelegate: TerminalDelegate {
        var colorChangeCount = 0
        var preserveBufferValues: [Bool] = []
        
        func colorChanged(source: Terminal, idx: Int?, preserveBuffer: Bool) {
            colorChangeCount += 1
            preserveBufferValues.append(preserveBuffer)
        }
        
        // Old method for backward compatibility
        func colorChanged(source: Terminal, idx: Int?) {
            // This should not be called with our implementation
            XCTFail("Old colorChanged method should not be called")
        }
        
        // Implement required methods from the protocol
        func showCursor(source: Terminal) {}
        func hideCursor(source: Terminal) {}
        func setTerminalTitle(source: Terminal, title: String) {}
        func setTerminalIconTitle(source: Terminal, title: String) {}
        @discardableResult
        func windowCommand(source: Terminal, command: Terminal.WindowManipulationCommand) -> [UInt8]? { return nil }
        func sizeChanged(source: Terminal) {}
        func send(source: Terminal, data: ArraySlice<UInt8>) {}
        func scrolled(source: Terminal, yDisp: Int) {}
        func linefeed(source: Terminal) {}
        func bufferActivated(source: Terminal) {}
        func bell(source: Terminal) {}
        func selectionChanged(source: Terminal) {}
        func isProcessTrusted(source: Terminal) -> Bool { return true }
        func mouseModeChanged(source: Terminal) {}
        func cursorStyleChanged(source: Terminal, newStyle: CursorStyle) {}
        func hostCurrentDirectoryUpdated(source: Terminal) {}
        func hostCurrentDocumentUpdated(source: Terminal) {}
        func setForegroundColor(source: Terminal, color: Color) {}
        func setBackgroundColor(source: Terminal, color: Color) {}
        func setCursorColor(source: Terminal, color: Color?) {}
        func getColors(source: Terminal) -> (foreground: Color, background: Color) {
            return (Color.defaultForeground, Color.defaultBackground)
        }
        func iTermContent(source: Terminal, content: ArraySlice<UInt8>) {}
        func clipboardCopy(source: Terminal, content: Data) {}
        func notify(source: Terminal, title: String, body: String) {}
        func createImageFromBitmap(source: Terminal, bytes: inout [UInt8], width: Int, height: Int) {}
        func createImage(source: Terminal, data: Data, width: ImageSizeRequest, height: ImageSizeRequest, preserveAspectRatio: Bool) {}
    }
    
    func testInstallPaletteWithPreserveBuffer() {
        let delegate = TestTerminalDelegate()
        let terminal = Terminal(delegate: delegate)
        
        // Default ANSI colors
        let colors = Color.defaultAnsiColors
        
        // Test normal install
        terminal.installPalette(colors: colors, preserveBuffer: false)
        XCTAssertEqual(delegate.colorChangeCount, 1)
        XCTAssertEqual(delegate.preserveBufferValues.last, false)
        
        // Test with preserveBuffer = true
        terminal.installPalette(colors: colors, preserveBuffer: true)
        XCTAssertEqual(delegate.colorChangeCount, 2)
        XCTAssertEqual(delegate.preserveBufferValues.last, true)
        
        // Test updateColorsOnly (should always set preserveBuffer to true)
        terminal.updateColorsOnly(colors: colors)
        XCTAssertEqual(delegate.colorChangeCount, 3)
        XCTAssertEqual(delegate.preserveBufferValues.last, true)
    }
    
    static var allTests = [
        ("testInstallPaletteWithPreserveBuffer", testInstallPaletteWithPreserveBuffer)
    ]
} 
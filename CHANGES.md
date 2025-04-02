# SwiftTerm Forked Changes

This document describes the changes made to the SwiftTerm library in this fork.

## Smooth Theme Switching

One of the main issues addressed in this fork is the screen clearing that occurs when switching terminal themes. Previously, when colors were changed, the entire terminal buffer would be reset, causing a momentary visual blank or flicker.

### Changes Made

1. Added `updateColorsOnly` method to `AppleTerminalView` that allows updating colors without causing a full screen refresh
2. Modified `colorsChanged` method to accept a `preserveBuffer` parameter controlling whether to trigger a full screen refresh
3. Updated `TerminalDelegate` protocol's `colorChanged` method to include a `preserveBuffer` parameter
4. Added a protocol extension for backward compatibility 
5. Added `preservingBufferDuringColorChange` tracking property to control drawing behavior
6. Added unit tests to verify the new functionality
7. Fixed implementation issues to avoid storing properties in extensions

### How to Use

Instead of calling the existing `installColors` method when changing themes, call the new `updateColorsOnly` method:

```swift
// Old way - causes screen to momentarily clear
terminalView.installColors(newColors)

// New way - preserves screen contents while updating colors
terminalView.updateColorsOnly(newColors)
```

Or use the lower-level API with the `preserveBuffer` parameter:

```swift
// Using the Terminal instance directly
terminal.installPalette(colors: newColors, preserveBuffer: true)
```

## Benefits

- Smoother user experience when switching themes
- No more momentary screen clearing when changing terminal colors
- Maintains backward compatibility with existing code

## Contributors

This improvement was based on an analysis documented in SwiftTermForkAnalysis.md. 
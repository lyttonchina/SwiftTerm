import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftTermTests.allTests),
        testCase(ColorChangeTests.allTests),
    ]
}
#endif

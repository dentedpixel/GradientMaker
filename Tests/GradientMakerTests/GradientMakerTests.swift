import XCTest
@testable import GradientMaker
import SwiftUI
 
final class GradientMakerTests: XCTestCase {
     func testExample() throws {
         // This is an example of a functional test case.
         // Use XCTAssert and related functions to verify your tests produce the correct
         // results.
         let view = GradientMaker(
            stops: [
                Gradient.Stop(color: Color.red, location: 0.0),
                Gradient.Stop(color: Color.yellow, location: 1.0)
            ],
            onUpdate: { _ in }
         )
         XCTAssertNotNil(view)
     }
 }


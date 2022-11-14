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
    
    func testGradientConversions() throws {
        let greenColor = Color(red: 0.0, green: 1.0, blue: 0.0)
        let redColor = Color(red: 1.0, green: 0.0, blue: 0.0)
        let greenUIColor = UIColor(greenColor)
        let redUIColor = UIColor(redColor)
        
        let greenStop = Gradient.Stop(color: greenColor, location: 0.2)
        let redStop = Gradient.Stop(color: redColor, location: 0.5)
        
        let gradient = Gradient(stops: [greenStop, redStop])
        
        let middle = gradient.value(at: 0.3)
        
        XCTAssertLessThan(middle.cgColor.components?.first ?? 0, UIColor(redStop.color).cgColor.components?.first ?? 0)
        
        let leftOutside = gradient.value(at: 0.1)
        let rightOutside = gradient.value(at: 0.7)
        
        XCTAssertEqual(greenUIColor, leftOutside)
        XCTAssertEqual(redUIColor, rightOutside)
    }
 }


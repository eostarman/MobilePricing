//  Created by Michael Rutherford on 1/3/21.

import Foundation

let christmasEve: Date = "12-24-2020"
let christmasDay: Date = "12-25-2020"
let dayAfterChristmas: Date = "12-26-2020"

// https://www.avanderlee.com/swift/expressible-literals/
extension Date: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self = formatter.date(from: value)!
    }
}

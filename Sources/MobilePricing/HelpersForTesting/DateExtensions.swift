//  Created by Michael Rutherford on 1/3/21.

import Foundation

let christmasEve: Date = "2020-12-24"
let christmasDay: Date = "2020-12-25"
let dayAfterChristmas: Date = "2020-12-26"

// https://www.avanderlee.com/swift/expressible-literals/
extension Date: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        guard let convertedDate = formatter.date(from: value) else {
            fatalError("\(value) is not a date in the format yyyy-MM-dd")
        }
        self = convertedDate
    }
}

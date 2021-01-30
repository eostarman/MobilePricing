//  Created by Michael Rutherford on 1/3/21.

import Foundation
import MoneyAndExchangeRates

extension MoneyWithoutCurrency: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        let amountAsString = "\(value)"
        guard let money = MoneyWithoutCurrency(amountAsString) else {
            fatalError("ERROR: Bad amount: '\(amountAsString)'")
        }
        self = money
    }
}

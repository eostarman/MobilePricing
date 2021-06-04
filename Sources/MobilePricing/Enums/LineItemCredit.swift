//  Created by Michael Rutherford on 2/11/21.

import Foundation
import MoneyAndExchangeRates

/// credits (for bags of empties and state pickup credits) assigned to an orderLine
public enum LineItemCredit: Equatable {
    case bagCredit(amount: MoneyWithoutCurrency)
    case statePickupCredit(amount: MoneyWithoutCurrency)
    
    public var amount: MoneyWithoutCurrency {
        switch self {
        case .bagCredit(let amount): return amount
        case .statePickupCredit(let amount): return amount
        }
    }
}
